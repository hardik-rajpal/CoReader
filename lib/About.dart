import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  AboutPage();
  String mainContent = '''This app is intended essentially as a handy glossary and notebook to be used while reading books.

It comes with an inbuilt connection to a dictionary, a note-making interface, a virtual bookmark and a sick UI.

For suggestions, queries, bug-reports (if it bothers you enough) or a cuppatea:
''';
  @override
  Widget build(BuildContext context) {
    return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8,20,8,8.0),
                  child: Column(
                    children: [
                      Text(
                        mainContent,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Email: hardikraj08@gmail.com',
                        style: TextStyle(
                            fontSize: 20
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(0,0,0,15),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      image: DecorationImage(
                          image: AssetImage('icon/icon.png')
                      )
                  ),
                  child: SizedBox.square(dimension: 70,),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Copyright Hardik Rajpal 2022.\nAll rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15
                    ),
                  ),
                )
            ],
            ),
              ),]
    );
  }
}
