import 'package:fish_redux/fish_redux.dart';

import 'effect.dart';
import 'reducer.dart';
import 'state.dart';
import 'view.dart';

class SearchOldResultPage extends Page<SearchResultState, Map<String, dynamic>> {
  SearchOldResultPage()
      : super(
            initState: initState,
            effect: buildEffect(),
            reducer: buildReducer(),
            view: buildView,
            dependencies: Dependencies<SearchResultState>(
                adapter: null,
                slots: <String, Dependent<SearchResultState>>{
                }),
            middleware: <Middleware<SearchResultState>>[
            ],);

}
