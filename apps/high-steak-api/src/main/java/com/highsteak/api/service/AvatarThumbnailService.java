package com.highsteak.api.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Iterator;

@Component
public class AvatarThumbnailService {

    static final int FEED_THUMB_DIMENSION_PX = 64;
    static final float JPEG_QUALITY = 0.82f;

    private final Path uploadsRoot;

    public AvatarThumbnailService(@Value("${app.uploads.dir}") String uploadsDir) {
        this.uploadsRoot = Path.of(uploadsDir).toAbsolutePath().normalize();
    }

    /**
     * Returns a cached small JPEG URL for feed listings, generated from the stored profile avatar.
     */
    public String resolveFeedThumbnailUrl(String avatarUrl) {
        if (avatarUrl == null || avatarUrl.isBlank()) {
            return null;
        }

        Path sourcePath = resolveSourcePath(avatarUrl);
        if (!Files.isRegularFile(sourcePath)) {
            return null;
        }

        String thumbPublicPath = feedThumbnailPublicPath(avatarUrl);
        Path thumbPath = resolveSourcePath(thumbPublicPath);
        if (Files.isRegularFile(thumbPath)) {
            return thumbPublicPath;
        }

        try {
            generateFeedThumbnail(sourcePath, thumbPath);
            return thumbPublicPath;
        } catch (IOException ex) {
            return null;
        }
    }

    private String feedThumbnailPublicPath(String avatarUrl) {
        String filename = Path.of(avatarUrl).getFileName().toString();
        int dot = filename.lastIndexOf('.');
        String base = dot > 0 ? filename.substring(0, dot) : filename;
        return "/uploads/avatars/thumbs/" + base + "-feed.jpg";
    }

    private Path resolveSourcePath(String publicPath) {
        String relative = publicPath.startsWith("/uploads/")
                ? publicPath.substring("/uploads/".length())
                : publicPath;
        Path resolved = uploadsRoot.resolve(relative).normalize();
        if (!resolved.startsWith(uploadsRoot)) {
            throw new IllegalArgumentException("Invalid upload path");
        }
        return resolved;
    }

    private void generateFeedThumbnail(Path sourcePath, Path thumbPath) throws IOException {
        BufferedImage source;
        try (InputStream input = Files.newInputStream(sourcePath)) {
            source = ImageIO.read(input);
        }
        if (source == null) {
            throw new IOException("Unsupported or invalid avatar image");
        }

        BufferedImage square = centerCropToSquare(source);
        BufferedImage resized = scaleToFit(square, FEED_THUMB_DIMENSION_PX);
        byte[] jpeg = encodeJpeg(resized);

        Files.createDirectories(thumbPath.getParent());
        Files.write(thumbPath, jpeg);
    }

    private static BufferedImage centerCropToSquare(BufferedImage source) {
        int size = Math.min(source.getWidth(), source.getHeight());
        int x = (source.getWidth() - size) / 2;
        int y = (source.getHeight() - size) / 2;
        return source.getSubimage(x, y, size, size);
    }

    private static BufferedImage scaleToFit(BufferedImage source, int maxDimension) {
        BufferedImage scaled = new BufferedImage(maxDimension, maxDimension, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = scaled.createGraphics();
        graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        graphics.drawImage(source, 0, 0, maxDimension, maxDimension, null);
        graphics.dispose();
        return scaled;
    }

    private static byte[] encodeJpeg(BufferedImage image) throws IOException {
        Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpeg");
        if (!writers.hasNext()) {
            throw new IOException("No JPEG writer available");
        }
        ImageWriter writer = writers.next();
        ImageWriteParam params = writer.getDefaultWriteParam();
        params.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
        params.setCompressionQuality(JPEG_QUALITY);

        try (var output = new java.io.ByteArrayOutputStream();
                ImageOutputStream imageOutput = ImageIO.createImageOutputStream(output)) {
            writer.setOutput(imageOutput);
            writer.write(null, new IIOImage(image, null, null), params);
            writer.dispose();
            return output.toByteArray();
        }
    }
}
