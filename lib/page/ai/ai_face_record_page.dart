import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widget/common_widget/common_widget.dart';

import 'ai_face_record_table_view.dart';
import 'ai_record_table_view.dart';

class AiFaceRecordPage extends StatefulWidget {
  int position = 0;

  AiFaceRecordPage({
    Key key,
    this.position,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AiFaceRecordPageState();
  }
}

class _AiFaceRecordPageState extends State<AiFaceRecordPage> {

  int currentIndex = 1;
  PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {});
  }

  void _selectMenu(int index) {
    currentIndex = index;
    _controller.jumpToPage(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            SizedBox(height: 16),
            Container(
              height: 30,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem("排队中", 0 == currentIndex, 0),
                  SizedBox(width: 20),
                  _buildMenuItem("生成成功", 1 == currentIndex, 1),
                  SizedBox(width: 20),
                  _buildMenuItem("生成失败", 2 == currentIndex, 2),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: _selectMenu,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return AiFaceRecordTableView(status: index == 2 ?  -1 :  index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectMenu(index),
      child: Container(
        width: 80,
        height: 30,
        alignment: Alignment.center,
        //color: isSelected ? Colors.white : Color.fromRGBO(204, 204, 204, 1),
        /*decoration: BoxDecoration(
          color:
              isSelected ? Color.fromRGBO(255, 101, 56, 1) : Color(0xff242424),
          borderRadius: BorderRadius.circular(4),
        ),*/
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Color.fromRGBO(204, 204, 204, 1),
                fontSize: 14,
              ),
            ),
            SizedBox(
              height: 3,
            ),
            isSelected
                ? Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xffff7f0f),
                    Color(0xffe38825),
                  ])),
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
