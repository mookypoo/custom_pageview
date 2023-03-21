import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomPageView extends StatefulWidget {
  const CustomPageView({Key? key, required this.pageController, required this.pages, required this.pageHeight}) : super(key: key);
  final PageController pageController;
  final List<Widget> pages;
  final double pageHeight;
  //final GlobalKey tabRowKey;
  //final double bottomStackHeight;
  
  @override
  State<CustomPageView> createState() => _CustomPageViewState();
}

class _CustomPageViewState extends State<CustomPageView> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<CustomValueNotifier<double>> _heightNotifiers = [];
  int _currentIndex = 0;
  List<double> _heights = [];

  @override
  void initState() {
    super.initState();
    this._heights = List<double>.generate(this.widget.pages.length, (int index) => this.widget.pageHeight);
    this._heightNotifiers = List<CustomValueNotifier<double>>.generate(this.widget.pages.length, (int index) => CustomValueNotifier(0.0, index));
    this._heightNotifiers.forEach((CustomValueNotifier<double> n) {
      n.addListener(() {
        /// textfield 올라올 때 MediaQuery.of(context) 을 사용하는 곳은 다 rebuild 가 되서
        /// 각 페이지 마다 notifier 따로 있으며, 해당 페이지에서만 rebuild 되게끔
        //print("index: ${n.index}, height: ${n.value}");
        if (n.index != this._currentIndex) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (n.value != this._heights[this._currentIndex]) {
            this._heights[this._currentIndex] = n.value;
            this.setState(() {});
          }
        });
      });
    });
  }

  @override
  void dispose() {
    this._heightNotifiers.forEach((ValueNotifier n) => n.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print("custom page view");
    return LayoutBuilder(
      builder: (_, __) {
        return SizedBox(
          height: this._heights[this._currentIndex],
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (int? i) {
              this._currentIndex = i!;
              /// height == 0.0 이면 height value notifier listener 에서 set state를 함 
              if (this._heights[this._currentIndex] != 0.0) this.setState(() {});
            },
            controller: this.widget.pageController,
            children: this.widget.pages.map((Widget widget) {
              final int _index = this.widget.pages.indexWhere((Widget page) => page.runtimeType == widget.runtimeType);
              return OverflowBox(
                maxHeight: double.infinity,
                //minHeight: this.widget.minHeight,
                minHeight: this.widget.pageHeight,
                //maxHeight: this._heights[this._currentIndex] != 0.0 ? this._heights[this._currentIndex] : double.infinity,
                child: CustomSizeTab(
                  child: widget,
                  heightNotifier: this._heightNotifiers[_index],
                ));
            }).toList(),
          ),
        );
      }
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// store info tab (index 0) 인 경우 notify listener를 다시 안할수도있어서 performLayout을 한번만 할 수 있음
/// 그래서 store info tab 이면 처음에 value notify 함
/// 제품 정보 / 실시간 댓글은 API 불르고 나서 notify 함
class CustomRenderObject extends RenderProxyBox {
  final CustomValueNotifier<double> heightNotifier;
  double? _initHeight;

  CustomRenderObject(this.heightNotifier);

  @override
  void performLayout() {
    super.performLayout();
    if (this._initHeight == null) {
      this._initHeight = child!.size.height;
      if (this.heightNotifier.index == 0) this.heightNotifier.value = this._initHeight!;
    } else {
      if (this._initHeight != child!.size.height) {
        this.heightNotifier.value = child!.size.height;
      } else {
        this.heightNotifier.value = this._initHeight!;
      }
    }
  }

  @override
  bool get sizedByParent => false;
}

class CustomSizeTab extends SingleChildRenderObjectWidget {
  final CustomValueNotifier<double> heightNotifier;

  CustomSizeTab({required super.child, required this.heightNotifier});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return CustomRenderObject(this.heightNotifier);
  }

}

class CustomValueNotifier<T> extends ValueNotifier<T>{
  final int index;

  CustomValueNotifier(super.value, this.index);
}
