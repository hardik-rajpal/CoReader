import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MinColorPicker extends StatefulWidget {
  final List<Color>? choices;
  bool? showValueBar = false;
  final Function onSelect;
  Color? selectedColor;
  MinColorPicker({this.choices, required this.onSelect, this.selectedColor, this.showValueBar});
  @override
  _MinColorPickerState createState() => _MinColorPickerState();
}

class _MinColorPickerState extends State<MinColorPicker> {
  List<Color> choices = [...Colors.primaries];
  Color selectedColor = Colors.blueAccent;
  double value = 1;
  bool showValueBar = false;
  // Map<String,double> rgbtohsv(int r,int g,int b){
  //   Map<String,double> map= {};
  //   double h,s,v;
  //
  //
  //   map['h'] = h;map['s'] = s;map['v'] = v;
  //   return map;
  // }
  // Map<String,double> hsvtorgb(int r,int g,int b){
  //   Map<String,double> map= {};
  //   return map;
  // }
  @override
  void initState() {
    if(widget.selectedColor!=null) {
      setState(() {
        selectedColor = widget.selectedColor!;
      });
    }
    setState(() {
      value = HSVColor.fromColor(selectedColor).value;
    });
    if(widget.choices!=null){
      setState(() {
        choices = widget.choices!;
      });
    }
    if(widget.showValueBar!=null){
      setState(() {
        showValueBar = widget.showValueBar!;
      });
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
            children: [
              Expanded(
                child: Center(
                  child: new Wrap(
                      children: choices.map((e) => ElevatedButton(
                      style: ButtonStyle(
                        fixedSize: MaterialStateProperty.all(Size.fromRadius(5)),
                        backgroundColor: MaterialStateProperty.all(e),
                        shape: MaterialStateProperty.all(CircleBorder())
                      ),
                          onPressed: (){
                            setState(() {
                              selectedColor = e;
                              value = HSVColor.fromColor(e).value;
                            });
                            widget.onSelect(e);
                          },
                          child: Container()
                    ),
                    ).toList(),
              ),
                ),
              )
            ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      color: selectedColor
                  ),
                ),
              ),
            (showValueBar)?Expanded(
              child: Slider(
                  min: 0.01,max: 1.0,
                  activeColor: selectedColor,
                  value: value,
                  autofocus: true,
                  onChanged: (v){
                    setState(() {
                      value = v;
                      selectedColor = HSVColor.fromColor(selectedColor).withValue(v).toColor();
                      // hsvcolor. = v;
                      //update selected color.
                    });
                  }
              ),
            ):Container(width: 0,height: 0,),
          ],
        )
      ],
    );
  }
}
