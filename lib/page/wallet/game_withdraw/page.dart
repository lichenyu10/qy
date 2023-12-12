import 'package:fish_redux/fish_redux.dart';

import 'effect.dart';
import 'reducer.dart';
import 'state.dart';
import 'view.dart';

class GameWithDrawPage extends Page<WithDrawState, Map<String, dynamic>> {
  GameWithDrawPage()
      : super(
          initState: initState,
          effect: buildEffect(),
          reducer: buildReducer(),
          view: buildView,
          dependencies: Dependencies<WithDrawState>(adapter: null, slots: <String, Dependent<WithDrawState>>{}),
          middleware: <Middleware<WithDrawState>>[],
        );
}