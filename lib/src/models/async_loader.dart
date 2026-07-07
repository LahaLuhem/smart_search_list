/// A page of async results together with whether more pages follow.
///
/// Returned by a [PagedAsyncLoader]. Where an [AsyncLoader] leaves the
/// controller to infer "are there more pages?" from the returned length
/// (`items.length == pageSize`), a [SearchPage] states [hasMore] explicitly.
///
/// This matters whenever the page-size heuristic doesn't hold:
/// - pages are variable-sized (e.g. one calendar day of entries per page), so
///   a short page is not the end of the data, and
/// - an empty page is not the end either (the next page may still have items).
///
/// Example:
/// ```dart
/// pagedAsyncLoader: (query, {page = 0, pageSize = 20}) async {
///   final result = await api.fetch(query, page: page);
///   return SearchPage(items: result.items, hasMore: result.nextCursor != null);
/// }
/// ```
class SearchPage<T> {
  /// The items loaded for this page. May be empty even when [hasMore] is true.
  final List<T> items;

  /// Whether another page can be loaded after this one.
  ///
  /// When false, the controller stops requesting pages and hides the
  /// load-more indicator.
  final bool hasMore;

  /// Creates a [SearchPage].
  const SearchPage({required this.items, required this.hasMore});
}

/// Loads a page of results as a plain list.
///
/// The controller infers whether more pages exist by comparing the returned
/// length against the configured page size — a full page (`items.length ==
/// pageSize`) implies more may follow, a short page ends pagination. Use a
/// [PagedAsyncLoader] instead when that heuristic doesn't fit your data.
///
/// Called with an empty [query] on initial load — handle `''` as "load all".
/// [page] is zero-based; [pageSize] reflects the configured page size.
typedef AsyncLoader<T> =
    Future<List<T>> Function(String query, {int page, int pageSize});

/// Loads a page of results and states explicitly whether more pages follow.
///
/// Returns a [SearchPage] carrying both the items and [SearchPage.hasMore], so
/// the controller never has to guess from the page size. See [SearchPage] for
/// when to prefer this over [AsyncLoader].
///
/// Called with an empty [query] on initial load; [page] is zero-based.
typedef PagedAsyncLoader<T> =
    Future<SearchPage<T>> Function(String query, {int page, int pageSize});
