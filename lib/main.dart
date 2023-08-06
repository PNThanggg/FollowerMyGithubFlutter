import 'dart:convert' show utf8, json;
import 'dart:io' show HttpHeaders, HttpClient;

import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

Future<Iterable<GithubUser>> getGithubFollowers(String accessToken) => HttpClient()
    .getUrl(Uri.parse('https://api.github.com/user/followers'))
    .then((req) {
      req.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
        ..set(HttpHeaders.contentTypeHeader, 'application/json');

      return req.close();
    })
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((jsonStr) => json.decode(jsonStr) as List<dynamic>)
    .then(
      (jsonArray) => jsonArray.compactMap((element) {
        if (element is Map<String, dynamic>) {
          return element;
        } else {
          return null;
        }
      }),
    )
    .then(
      (listOfMaps) => listOfMaps.map(
        (map) => GithubUser.fromMap(map),
      ),
    );


class GithubUser {
  final String username;
  final String avatarUrl;

  GithubUser.fromMap(Map<String, dynamic> map)
      : username = map['login'] as String,
        avatarUrl = map['avatar_url'] as String;
}

extension CompactMap<T> on List<T> {
  List<E> compactMap<E>(E? Function(T element) f) {
    Iterable<E> imp(E? Function(T element) f) sync* {
      for (final value in this) {
        final mapped = f(value);
        if (mapped != null) {
          yield mapped;
        }
      }
    }

    return imp(f).toList();
  }
}

const token = '################################';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub API in Flutter'),
      ),
      body: FutureBuilder(
        future: getGithubFollowers(token),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final users = (snapshot.data as Iterable<GithubUser>).toList();
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(
                      user.username,
                    ),
                    leading: Image.network(
                      user.avatarUrl,
                    ),
                  );
                },
              );
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
    );
  }
}
