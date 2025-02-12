import 'package:fish_redux/fish_redux.dart';

import 'effect.dart';
import 'reducer.dart';
import 'state.dart';
import 'view.dart';

class MineBillItemComponent extends Component<MineBillItemState> {
  MineBillItemComponent()
      : super(
            effect: buildEffect(),
            reducer: buildReducer(),
            view: buildView,
            dependencies: Dependencies<MineBillItemState>(
                adapter: null,
                slots: <String, Dependent<MineBillItemState>>{
                }),);

}
