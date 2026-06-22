package com.highsteak.api.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AvatarThumbnailServiceTest {

    @TempDir
    Path uploadsDir;

    @Test
    void resolveFeedThumbnailUrlGeneratesCachedSquareJpeg() throws IOException {
        Path avatarFile = uploadsDir.resolve("avatar-test.jpg");
        writeJpeg(avatarFile, 800, 600, Color.RED);

        AvatarThumbnailService service = new AvatarThumbnailService(uploadsDir.toString());
        String thumbUrl = service.resolveFeedThumbnailUrl("/uploads/avatar-test.jpg");

        assertNotNull(thumbUrl);
        assertEquals("/uploads/avatars/thumbs/avatar-test-feed.jpg", thumbUrl);

        Path thumbFile = uploadsDir.resolve("avatars/thumbs/avatar-test-feed.jpg");
        assertTrue(Files.isRegularFile(thumbFile));
        assertTrue(Files.size(thumbFile) < Files.size(avatarFile) / 10);

        BufferedImage thumb = ImageIO.read(thumbFile.toFile());
        assertEquals(AvatarThumbnailService.FEED_THUMB_DIMENSION_PX, thumb.getWidth());
        assertEquals(AvatarThumbnailService.FEED_THUMB_DIMENSION_PX, thumb.getHeight());

        String cached = service.resolveFeedThumbnailUrl("/uploads/avatar-test.jpg");
        assertEquals(thumbUrl, cached);
    }

    @Test
    void resolveFeedThumbnailUrlReturnsNullWhenAvatarMissing() {
        AvatarThumbnailService service = new AvatarThumbnailService(uploadsDir.toString());
        assertEquals(null, service.resolveFeedThumbnailUrl("/uploads/missing.jpg"));
    }

    private static void writeJpeg(Path path, int width, int height, Color color) throws IOException {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = image.createGraphics();
        graphics.setColor(color);
        graphics.fillRect(0, 0, width, height);
        graphics.dispose();

        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageIO.write(image, "jpeg", output);
        Files.write(path, output.toByteArray());
    }
}
