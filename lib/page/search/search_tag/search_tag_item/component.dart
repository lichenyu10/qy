import 'package:fish_redux/fish_redux.dart';

import 'effect.dart';
import 'reducer.dart';
import 'state.dart';
import 'view.dart';

class SearchTagItemComponent extends Component<SearchTagItemState> {
  SearchTagItemComponent()
      : super(
            effect: buildEffect(),
            reducer: buildReducer(),
            view: buildView,
            dependencies: Dependencies<SearchTagItemState>(
                adapter: null,
                slots: <String, Dependent<SearchTagItemState>>{
                }),);

}
