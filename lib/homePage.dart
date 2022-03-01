import 'dart:convert';
import 'dart:ui';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maria/api/api.dart';
import 'package:maria/model/musicModel.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _launchInWebViewOrVC(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: true,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      print("error");
    }
  }

  List<Map> messsages = [];
  final List<MusicModel> items = [];
  final messageInsert = TextEditingController();
  bool tromperie = false;
  var lastMot;

  void correction(String word, String artiste) async {
    final http.Response response = await http.get(
        Uri.parse(
          'http://172.16.8.113:8080/correct?text=$word&rappeur=$artiste',
        ),
        headers: {"Accept": "application/json"});

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      var result = responseData['response'];
      if (result == 1) {
        setState(() {
          messsages.insert(0, {
            "data": 0,
            "message":
                "C'est corrigé! Redemande le moi une autre fois et tu verras que je ne l'aurais pas oublié 🤓",
          });
          tromperie = false;
        });
      }
    } else {
      print("not 200");
    }
  }

  void searchText(String word) async {
    final http.Response response = await http.get(
        Uri.parse(
          Url.searchText + word,
        ),
        headers: {"Accept": "application/json"});

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print(responseData["results"]);
      if (responseData["results"] == 0) {
        setState(() {
          messsages.insert(0, {
            "data": 0,
            "message":
                "Je n'ai trouvé aucun résultat.. Dis 'Correction' pour m'apprendre qui chante ça",
          });
        });
      } else {
        var result = responseData['results'];
        if (result.isNotEmpty) {
          var spotifyUrl = result[0]["external_urls"]["spotify"];
          var followers = result[0]["followers"]["total"];
          print(spotifyUrl);
          var artistName = result[0]["name"];
          result?.forEach((theArtist) {
            final MusicModel artist = MusicModel(
              artiste: artistName,
              image: artistName,
              followers: followers.toString(),
              spotifyUrl: spotifyUrl,
            );
            setState(() {
              items.add(artist);
              messsages.insert(0, {
                "data": 0,
                "message": "Le rappeur qui a rappé ce morceau est : " +
                    artistName +
                    "\n Si la réponse est incorrecte, écrivez : Faux",
              });
              Future.delayed(const Duration(seconds: 2), () {
                _showDialog(
                    context, artistName, spotifyUrl, followers.toString());
              });
            });
          });
        } else {
          setState(() {
            messsages.insert(0, {
              "data": 0,
              "message":
                  "Je n'ai malheureusement pas trouvé le rappeur qui a chanté ça.. tu peux m'aider ? Ecris correction",
            });
          });
        }
      }
    } else {
      print("not 200");
    }
  }

  void _showDialog(BuildContext context, String artist, String spotifyUrl,
      String followers) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AlertDialog(
            title: Text(artist),
            content: Text(artist + " a " + followers + " abonnés sur Spotify"),
            actions: <Widget>[
              new FlatButton(
                child: const Text(
                  "Fermer",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: const Text(
                  "Voir sur Spotify",
                  style: TextStyle(
                    color: Colors.green,
                  ),
                ),
                onPressed: () {
                  print("spotify");
                  _launchInWebViewOrVC(spotifyUrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget chat(String message, int data) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Bubble(
          radius: const Radius.circular(15.0),
          color: data == 0 ? Colors.deepOrange : Colors.blue,
          elevation: 0.0,
          alignment: data == 0 ? Alignment.topLeft : Alignment.topRight,
          nip: data == 0 ? BubbleNip.leftBottom : BubbleNip.rightTop,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(
                      data == 0 ? "assets/maria.png" : "assets/user.png"),
                ),
                const SizedBox(
                  width: 10.0,
                ),
                Flexible(
                    child: Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ))
              ],
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffDFCFBE),
        title: const Text(
          "Maria",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xffDFCFBE),
        child: SafeArea(
          child: Container(
            color: const Color(0xffDFCFBE),
            child: Column(
              children: [
                Flexible(
                  child: messsages != []
                      ? ListView.builder(
                          reverse: true,
                          itemCount: messsages.length,
                          itemBuilder: (context, index) => chat(
                            messsages[index]["message"],
                            messsages[index]["data"],
                          ),
                        )
                      : const SizedBox(height: 0),
                ),
                const Divider(
                  height: 5.0,
                  color: Colors.deepOrange,
                ),
                Container(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: TextField(
                          controller: messageInsert,
                          decoration: const InputDecoration.collapsed(
                            hintText: "Envoie un message",
                            hintStyle: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18.0),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.deepOrange,
                            size: 30,
                          ),
                          onPressed: () {
                            if (messageInsert.text.isEmpty) {
                              // ignore: avoid_print
                              print("empty message");
                            } else {
                              if (messageInsert.text == "Faux") {
                                setState(() {
                                  tromperie = true;
                                  print("mode correction activé: " +
                                      tromperie.toString());
                                  messsages.insert(0, {
                                    "data": 1,
                                    "message": messageInsert.text
                                  });
                                  messageInsert.clear();
                                  messsages.insert(0, {
                                    "data": 0,
                                    "message":
                                        "Oups, j'ai du faire une petite erreur.. tu peux me rappeller qui a chanté ça ?",
                                  });
                                });
                              } else {
                                if (messageInsert.text == "Correction") {
                                  setState(() {
                                    tromperie = true;
                                    messsages.insert(0, {
                                      "data": 1,
                                      "message": messageInsert.text
                                    });
                                    print("mode correction activé: " +
                                        tromperie.toString());
                                    messageInsert.clear();
                                    messsages.insert(0, {
                                      "data": 0,
                                      "message":
                                          "Dis moi qui est le chanteur qui a chanté ça ?",
                                    });
                                  });
                                } else {
                                  setState(() {
                                    if (tromperie == false) {
                                      lastMot = messageInsert.text;
                                      messsages.insert(0, {
                                        "data": 1,
                                        "message": messageInsert.text
                                      });
                                    }
                                    if (tromperie == true) {
                                      setState(() {
                                        messsages.insert(0, {
                                          "data": 1,
                                          "message": messageInsert.text
                                        });
                                      });

                                      correction(lastMot, messageInsert.text);
                                    } else {
                                      searchText(messageInsert.text);
                                    }
                                    messageInsert.clear();
                                  });
                                }
                              }

                              //response(messageInsert.text);
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
