import 'package:flutter/foundation.dart';

import '../models/page_response.dart';

class PaginatedListController<T> extends ChangeNotifier {
  PaginatedListController(this._loadPage);

  final Future<PageResponse<T>> Function(int page) _loadPage;

  final List<T> items = [];
  int _page = 0;
  int totalElements = 0;
  bool hasMore = false;
  bool loading = false;
  bool loadingMore = false;
  String? error;

  Future<void> reload() async {
    loading = true;
    loadingMore = false;
    error = null;
    items.clear();
    _page = 0;
    hasMore = false;
    totalElements = 0;
    notifyListeners();

    try {
      final response = await _loadPage(0);
      items.addAll(response.content);
      _page = response.page;
      totalElements = response.totalElements;
      hasMore = response.page + 1 < response.totalPages;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();

    try {
      final response = await _loadPage(_page + 1);
      items.addAll(response.content);
      _page = response.page;
      totalElements = response.totalElements;
      hasMore = response.page + 1 < response.totalPages;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  void removeWhere(bool Function(T item) test) {
    items.removeWhere(test);
    notifyListeners();
  }

  void addItem(T item) {
    items.add(item);
    notifyListeners();
  }
}
