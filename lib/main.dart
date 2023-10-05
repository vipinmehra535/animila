import 'package:animila/secerts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Animal Pictures',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> images = [];
  TextEditingController searchController = TextEditingController();
  int page = 1;
  bool isLoading = false;
  bool hasMore = true;

  //Fetching Images from API

  Future<void> fetchImages(String query, int page) async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    final String apiUrl =
        'https://api.unsplash.com/search/photos?page=$page&query=$query';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Client-ID $unsplashApiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageList = data['results'] as List<dynamic>;

        List<String> newImages = [];

        for (var item in imageList) {
          newImages.add(item['urls']['regular']);
        }

        setState(() {
          images.addAll(newImages);
          isLoading = false;
          if (imageList.isEmpty) {
            hasMore = false;
          }
        });
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Picture App'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onSubmitted: (value) {
                images.clear();
                page = 1;
                hasMore = true;
                fetchImages(searchController.text, page);
              },
              controller: searchController,
              decoration: InputDecoration(
                // enabledBorder: const OutlineInputBorder(),
                border: const OutlineInputBorder(),
                hintText: 'Search for animals',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    images.clear();
                    page = 1;
                    hasMore = true;
                    fetchImages(searchController.text, page);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo is ScrollEndNotification &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  if (hasMore) {
                    page++;
                    fetchImages(searchController.text, page);
                  }
                }
                return true;
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 1,
                    crossAxisCount: 2,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
          ),
          isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: LinearProgressIndicator(
                      color: Colors.black,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
