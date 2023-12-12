import 'dart:convert';

import 'package:fish_redux/fish_redux.dart';
import 'package:flutter_alipay/flutter_alipay.dart';
import 'package:flutter_app/assets/lang.dart';
import 'package:flutter_app/common/config/config.dart';
import 'package:flutter_app/common/local_router/jump_router.dart';
import 'package:flutter_app/common/config/address.dart';
import 'package:flutter_app/common/manager/cs_manager.dart';
import 'package:flutter_app/common/net2/net_manager.dart';
import 'package:flutter_app/global_store/store.dart';
import 'package:flutter_app/model/wallet/recharge_url_model.dart';
import 'package:flutter_app/page/wallet/pay_for/model.dart';
import 'package:flutter_app/page/wallet/pay_for/model/pay_type.dart';
import 'package:flutter_app/common/local_router/route_map.dart';
import 'package:flutter_app/widget/dialog/discount_rechg.dart';
import 'package:flutter_base/eagle/umeng_util.dart';
import 'package:flutter_app/widget/dialog/confirm_dialog.dart';
import 'package:flutter_app/widget/dialog/payfor_confirm_dialog.dart';
import 'package:flutter_base/flutter_base.dart';

import 'package:flutter_base/utils/log.dart';
import 'package:flutter_base/utils/toast_util.dart';
import 'package:flutter_app/utils/utils.dart';

import 'action.dart';
import 'state.dart';

Effect<PayForState> buildEffect() {
  return combineEffects(<Object, Effect<PayForState>>{
    PayForAction.conventional: _onConventional,
    PayForAction.glodBuyVip: _onGlodBuyVip,
    Lifecycle.initState: _init,
    Lifecycle.dispose: _dispose,
  });
}

void _init(Action action, Context<PayForState> ctx) {

}

void _onGlodBuyVip(Action action, Context<PayForState> ctx) async {
  if (ctx.state.vipItem == null) {
    showToast(msg: "vipItem 为空，购买vip失败");
    if (ctx.state.needBackArgs ?? false) {
      safePopPage("pay_vip_fail");
    }
    return;
  }
  var name = TextUtil.isNotEmpty(ctx.state.vipItem?.productName)
      ? ctx.state.vipItem?.productName
      : ctx.state.vipItem?.productID;
  eagleClick(ctx.state.selfId(),
      sourceId: ctx.state.eagleId(ctx.context), label: "gold_buy$name");

  if (ctx.state.curTabVipItem != null &&
      ctx.state.curTabVipItem.showType == 1) {
    await openDiscountBottomSheet(
        context: ctx.context, vipItem: ctx.state.vipItem);
    if (ctx.state.needBackArgs ?? false) {
      safePopPage("");
    }
    return;
  }

  ctx.dispatch(PayForActionCreator.payLoading(true));
  var result;
  try {
    ///购买认证
    if (ctx.state.vipItem.productType == 16) {
      result = await netManager.client.postBuyOfficicalCert(
          ctx.state.vipItem.productID, ctx.state.vipItem.productType);
      l.e("购买认证", "购买认证()...result:$result");
    } else {
      result = await netManager.client.buyVipProduct(
          ctx.state.vipItem.productType,
          ctx.state.vipItem.productID,
          ctx.state.vipItem.productName,
          ctx.state.vipItem.discountedPrice);
      l.e("member_center", "buyVipProduct()...result:$result");
    }
  } catch (e) {
    l.e("member_center", "buyVipProduct()...error:$e");
  }
  ctx.dispatch(PayForActionCreator.payLoading(false));
  if (null == result) {
    showToast(msg: "购买失败");
    if (ctx.state.needBackArgs ?? false) {
      safePopPage("pay_vip_fail");
    }
    return;
  }

  if (ctx.state.vipItem?.productType == 16) {
    showToast(msg: "提交审核成功～");
  } else {
    showToast(
        msg: Lang.sprint(Lang.SUCCESSFUL_PURCHASE,
            args: [ctx.state.vipItem.productName]));
  }

  if (ctx.state.isDialog) {
    safePopPage();
  } else {
    if (ctx.state.needBackArgs ?? false) {
      safePopPage("pay_vip_success");
    }
  }
  if (ctx.state.vipItem?.productType != 16) {
    _showPayforHintDialog(ctx);
  }

  GlobalStore.updateUserInfo(null);
  ctx.dispatch(PayForActionCreator.payLoading(false));
}

// 官方充值
void _onConventional(Action action, Context<PayForState> ctx) async {
  var index = action.payload;
  if ((ctx.state.payList ?? []).isEmpty) {
    l.e("购买会员：", "官方充值payList为空");
    return;
  }
  PayType payType = ctx.state.payList[index];
  if (payType.isOfficial) {
    _onPayFor(payType, ctx);
    return;
  }
  ctx.dispatch(PayForActionCreator.payLoading(true));

  String rechargeType = payType.type;
  String vipID;
  String productId;
  String eagleName = "";
  if (ctx.state.vipItem != null) {
    /// 购买会员卡
    l.e("购买方式：", "购买会员卡， 金额：${ctx.state.rechargeModel?.money}");
    vipID = ctx.state.vipItem.productID;
    eagleName = TextUtil.isNotEmpty(ctx.state.vipItem?.productName)
        ? ctx.state.vipItem?.productName
        : ctx.state.vipItem?.productID;
  } else {
    /// 购买金币
    l.e("购买方式：", "购买金币， 金额：${ctx.state.rechargeModel?.money}");
    productId = ctx.state.rechargeModel?.id;
    eagleName = TextUtil.isNotEmpty(ctx.state.rechargeModel?.money?.toString())
        ? ctx.state.rechargeModel?.money?.toString()
        : ctx.state.rechargeModel?.id;
  }

  eagleClick(ctx.state.selfId(),
      sourceId: ctx.state.eagleId(ctx.context),
      label: "$rechargeType$eagleName");
  try {
    RechargeUrlModel rechargeUrlModel;

    rechargeUrlModel = await netManager.client.chargeGoldCoin(
        rechargeType,
        vipID == null || vipID == "" ? productId : vipID,
        vipID == null || vipID == "" ? false : true,Config.goldTicketList == null ? "" : Config.goldTicketList.cId );

    if (rechargeUrlModel.mode == "url") {
      launchUrl(rechargeUrlModel.payUrl);
    } else if (rechargeUrlModel.mode == "sdk") {
      await showConfirm(ctx.context, content: Lang.FIVE_MINS_PAY_TIPS);
      if (payType?.type == 'alipay') {
        AlipayResult result = await FlutterAlipay.pay(rechargeUrlModel.payUrl);
        if (result.resultStatus == "9000") {
          await showConfirm(ctx.context, content: Lang.PAY_SUCCESS);
        } else {
          showToast(msg: Lang.PAY_ERROR + result.toString());
        }
      } else {
        showToast(msg: "没有找到支付类型为:${payType?.type} 的sdk");
      }
    }
  } catch (e) {
    showToast(msg: e.toString());
    l.e("pay", "error in pay:$e");
  } finally {
    if (ctx.state.isDialog) {
      safePopPage();
    }
    GlobalStore.refreshWallet();
    _showPayforHintDialog(ctx);
  }
  ctx.dispatch(PayForActionCreator.payLoading(false));

  Config.goldTicketList = null;
}

_showPayforHintDialog(Context<PayForState> ctx) async {
  if (ctx.state.vipItem == null) {
    return;
  }
  var title = "已支付";
  var res = await showPayForConfirmDialog(FlutterBase.appContext);
  if (res == title) {
    //已经支付，刷新用户信息
    GlobalStore.updateUserInfo(null);
    safePopPage();
  } else if (res == "question") {
    //进入在线客服
    csManager.openServices(ctx.context);
  }
}

class ProductInfo {
  ///商品id
  String id;

  /// 0 金币，1 商品
  int type;

  String version = "3.0.0";

  Map toJson() => {
        "id": id,
        "type": type,
        "version": version,
      };
}

///代充支付
void _onPayFor(PayType payType, Context<PayForState> ctx) async {
  if (ctx.state.isDialog) {
    safePopPage();
  }
  DCModel dcModel = ctx.state.dcModel.clone();
  ProductInfo productInfo = ProductInfo();
  var eagleName = "";
  if (ctx.state.vipItem != null) {
    /// 购买会员卡 2是裸聊  3是果币
    productInfo.type = 1;
    productInfo.id = ctx.state.vipItem.productID;
    eagleName = TextUtil.isNotEmpty(ctx.state.vipItem?.productName)
        ? ctx.state.vipItem?.productName
        : ctx.state.vipItem?.productID;
  } else {
    /// 购买金币 2是裸聊  3是果币
    eagleName = TextUtil.isNotEmpty(ctx.state.rechargeModel?.money?.toString())
        ? ctx.state.rechargeModel?.money?.toString()
        : ctx.state.rechargeModel?.id;

    productInfo.type = 0;
    productInfo.id = ctx.state.rechargeModel.id;
  }

  eagleClick(ctx.state.selfId(),
      sourceId: ctx.state.eagleId(ctx.context), label: "daichong$eagleName");

  dcModel.productInfo = json.encode(productInfo).toString();
  List<PayInfoModel> payList = dcModel.traders[0].payInfos;
  PayInfoModel payInfoModel;
  for (PayInfoModel model in payList) {
    if (model.payMethod == payType.payMethod) {
      payInfoModel = model;
      break;
    }
  }
  //设置默认值
  if (dcModel.limit == 0) {
    dcModel.limit = 500;
  }

  if (payInfoModel.payType.contains(2) && payInfoModel.payType.contains(3)) {
    if ((ctx.state.payMoney / 100) > dcModel.limit) {
      payInfoModel.payType = [3];
    } else {
      payInfoModel.payType = [2];
    }
  }

  if (payInfoModel.payType.length >= 3) {
    if ((ctx.state.payMoney / 100) > dcModel.limit) {
      payInfoModel.payType = [1, 3];
    } else {
      payInfoModel.payType = [1, 2];
    }
  }

  var list = [payInfoModel];
  dcModel.traders[0].payInfos = list;

  String line = Address.baseHost;
  dcModel.ordUrl = line + dcModel.ordUrl;
  dcModel.traderUrl = line + dcModel.traderUrl;
  dcModel.chargeMoney = ctx.state.payMoney ~/ 100;
  String channel = payType.channel;
  String token = await netManager.getToken();
  //bt64
  String models = json.encode(dcModel).toString();
  String url = channel + "/?data=" + _encodeBase64(models) + "&token=" + token;
  Map<String, dynamic> arguments = {"title": Lang.PROXY_RECHARGE, "url": url};
  // 跳转链接
  await JRouter().go(PAGE_WEB, arguments: arguments);
  _showPayforHintDialog(ctx);
}

/*
  * Base64加密
  */
String _encodeBase64(String data) {
  var content = utf8.encode(data);
  var digest = base64Encode(content);
  return digest;
}

void _dispose(Action action, Context<PayForState> ctx) {
  ctx.state.payRadioType = 0;
  ctx.state.scrollController?.dispose();
}