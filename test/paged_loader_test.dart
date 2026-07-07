import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Tests for [SmartSearchController.setPagedAsyncLoader] and [SearchPage] — the
/// explicit-hasMore loader contract, where the loader decides whether more
/// pages exist instead of the controller inferring it from the page size.
void main() {
  group('setPagedAsyncLoader — explicit hasMore', () {
    test('initial load takes items and hasMore from the SearchPage', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);

      controller.setPagedAsyncLoader(
        (query, {int page = 0, int pageSize = 20}) async =>
            const SearchPage(items: ['a', 'b'], hasMore: true),
      );

      controller.searchImmediate('');
      await Future.microtask(() {});

      expect(controller.items, ['a', 'b']);
      // hasMore is true even though only 2 items came back for pageSize 10 —
      // the count heuristic (2 == 10) would have wrongly said false here.
      expect(controller.hasMorePages, true);
    });

    test('loadMore appends the next page and honours its hasMore', () async {
      final pages = <SearchPage<String>>[
        const SearchPage(items: ['p0'], hasMore: true),
        const SearchPage(items: ['p1'], hasMore: false),
      ];
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);
      controller.setPagedAsyncLoader(
        (query, {int page = 0, int pageSize = 20}) async => pages[page],
      );

      controller.searchImmediate('');
      await Future.microtask(() {});

      await controller.loadMore();
      expect(controller.items, ['p0', 'p1']);
      expect(controller.hasMorePages, false);
    });

    test(
      'empty page with hasMore true keeps paging (the day-level case)',
      () async {
        final pages = <SearchPage<String>>[
          const SearchPage(items: ['day0'], hasMore: true),
          const SearchPage(items: [], hasMore: true), // empty day, more to come
          const SearchPage(items: ['day2a', 'day2b'], hasMore: false),
        ];
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          pageSize: 10,
        );
        addTearDown(controller.dispose);
        controller.setPagedAsyncLoader(
          (query, {int page = 0, int pageSize = 20}) async => pages[page],
        );

        controller.searchImmediate('');
        await Future.microtask(() {});
        expect(controller.items, ['day0']);
        expect(controller.hasMorePages, true);

        // Page 1 is empty but reports hasMore: true. The old count heuristic
        // (and the old empty-results guard) would have terminated here.
        await controller.loadMore();
        expect(controller.items, ['day0']);
        expect(controller.hasMorePages, true);

        // Page 2 finally ends the run.
        await controller.loadMore();
        expect(controller.items, ['day0', 'day2a', 'day2b']);
        expect(controller.hasMorePages, false);
      },
    );

    test('loadMore is a no-op once hasMore is false', () async {
      var calls = 0;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);
      controller.setPagedAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        calls++;
        return const SearchPage(items: ['only'], hasMore: false);
      });

      controller.searchImmediate('');
      await Future.microtask(() {});
      expect(calls, 1);
      expect(controller.hasMorePages, false);

      await controller.loadMore();
      expect(calls, 1); // guard on !_hasMorePages short-circuits
      expect(controller.items, ['only']);
    });

    test('setAsyncLoader still infers hasMore from the page size', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 2,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(
        (query, {int page = 0, int pageSize = 20}) async =>
            page == 0 ? ['a', 'b'] : ['c'],
      );

      controller.searchImmediate('');
      await Future.microtask(() {});
      expect(controller.hasMorePages, true); // full page (2 == 2) → more

      await controller.loadMore();
      expect(controller.items, ['a', 'b', 'c']);
      expect(controller.hasMorePages, false); // partial page (1 != 2) → stop
    });
  });
}
