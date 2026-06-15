import 'package:flutter_test/flutter_test.dart';
import 'package:high_steak_mobile/utils/api_image_url.dart';

void main() {
  test('upload paths include /api context like the web client', () {
    expect(
      resolveApiImageUrl('/uploads/steak.jpg'),
      'http://127.0.0.1:8080/api/uploads/steak.jpg',
    );
  });

  test('paths without leading slash are normalized', () {
    expect(
      resolveApiImageUrl('uploads/steak.jpg'),
      'http://127.0.0.1:8080/api/uploads/steak.jpg',
    );
  });

  test('absolute URLs are unchanged', () {
    const absolute = 'https://cdn.example.com/photo.jpg';
    expect(resolveApiImageUrl(absolute), absolute);
  });

  test('empty paths resolve to empty string', () {
    expect(resolveApiImageUrl(null), '');
    expect(resolveApiImageUrl(''), '');
  });

  test('resolvePostImageUrls filters blanks', () {
    expect(
      resolvePostImageUrls(['/uploads/a.jpg', '', '/uploads/b.jpg']),
      [
        'http://127.0.0.1:8080/api/uploads/a.jpg',
        'http://127.0.0.1:8080/api/uploads/b.jpg',
      ],
    );
  });
}
