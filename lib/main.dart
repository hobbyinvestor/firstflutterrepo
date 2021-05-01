import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await client
      .get(Uri.parse('https://multifeed.org/wp-json/fcn-rest/v1/geheim'));
  print('Loading DATA JSON');
  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parsePhotos, response.body);
}

// A function that converts a response body into a List<Photo>.
List<Photo> parsePhotos(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
}

class Photo {
  final String author;
  final String date;
  final String title;
  final String link;
  final String imagelinkthumbnail;

  Photo({this.author, this.date, this.title, this.link, this.imagelinkthumbnail});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      author: json['author'] as String,
      date: json['date'] as String,
      title: json['title'] as String,
      link: json['original_link'] as String,
      imagelinkthumbnail: json['image_link_thumbnail'] as String,
    );
  }
}

void main() => runApp(new MaterialApp( home: new MyApp()));

class MyApp extends StatefulWidget {
 @override
  _State createState() => new _State('FinanzFeed.de');
}

class _State extends State<MyApp>{
  final String title;
  _State(this.title);
  String _value = "";
  List<BottomNavigationBarItem> _items;

  void _onClick(String value) => print ("clicked");

  int _index = 0;
  @override
  void initState(){
    _items = [];
    _items.add(new BottomNavigationBarItem(icon: new Icon(Icons.people), label: 'People'));
    _items.add(new BottomNavigationBarItem(icon: new Icon(Icons.weekend), label: 'Weekend'));
    _items.add(new BottomNavigationBarItem(icon: new Icon(Icons.message), label: 'Message'));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: new Drawer(
        child: new Container(
          padding: new EdgeInsets.all(32.0),
          child: new Column(
            children: <Widget>[
              new Text("Hello Drawer"),
              new ElevatedButton(onPressed: () => Navigator.pop(context), child: new Text('Close'),)
            ],
        )
        )
      ),
      bottomNavigationBar: new BottomNavigationBar(
        items: _items,
        fixedColor: Colors.blue,
      currentIndex: _index,
      onTap: (int item) {
          setState((){
            _index = item;
            _value = "Current Value is: ${_index.toString()}";
          });},
      ),
      persistentFooterButtons: <Widget>[
        new IconButton(onPressed: () => _onClick("Button1"), icon: new Icon(Icons.timer))
      ],
      body: FutureBuilder<List<Photo>>(
        future: fetchPhotos(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);
          return new RefreshIndicator(
              color: Colors.blue,
              onRefresh: () async {
                List<Photo> ls = await fetchPhotos(http.Client());
                return PhotosList(photos: ls); // EDITED
              },
          child: PhotosList(photos: snapshot.data)
            );
          //return snapshot.hasData
            //  ? PhotosList(photos: snapshot.data)
              //: Center(child: CircularProgressIndicator());
        },),
    );
  }
}



class PhotosList extends StatelessWidget {
  final List<Photo> photos;

  PhotosList({Key key, this.photos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 20
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        print ("link: "+photos[index].link);
        return new Card (
          child: new InkWell(
            onTap: () async {
              print (photos[index].link);
              await launch(photos[index].link, forceWebView: true,forceSafariVC: true, enableJavaScript: true,);
            },
            child: new Card(
                clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Image.network(photos[index].imagelinkthumbnail),
                  ListTile(
                      leading: Icon(Icons.text_snippet_outlined),
                      title: Text(photos[index].title),
                      subtitle: Text(
                        'veröffentlicht von '+photos[index].author,
                        style: TextStyle(color: Colors.black.withOpacity(0.6)),
                      ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        label: Text ('(2)'),
                        onPressed: () {
                          // Perform some action
                        },
                        icon: Icon(Icons.thumb_up, color: Colors.green),

                      ),
                      TextButton.icon(
                        label: Text('(3)'),
                        onPressed: () {
                          // Perform some action
                        },
                        icon: Icon(Icons.thumb_down,color: Colors.red),
                      ),
                    ],
                  ),
                ],
              )
            ),
          )
         );
      },

    );
  }

}
