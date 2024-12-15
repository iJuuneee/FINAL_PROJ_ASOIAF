import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(IceAndFireApp());
}

class IceAndFireApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        textTheme: TextTheme(
          displayLarge: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ice and Fire Database'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/book_cover.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => DetailsScreen()));
                },
                child: Text('Explore Characters'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => GuessGameScreen()));
                },
                child: Text('Guess the Character'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  List characters = [];
  List filteredCharacters = [];
  List favorites = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortBy = 'name';

  @override
  void initState() {
    super.initState();
    fetchCharacters();
  }

  Future<void> fetchCharacters() async {
    setState(() => isLoading = true);
    try {
      final newCharacters = await ApiService.getAllCharacters();
      setState(() {
        characters = newCharacters;
        filteredCharacters = newCharacters;
        applySorting();
      });
    } catch (e) {
      print('Error fetching characters: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applySorting() {
    setState(() {
      if (sortBy == 'name') {
        filteredCharacters.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      } else if (sortBy == 'gender') {
        filteredCharacters.sort((a, b) => (a['gender'] ?? '').compareTo(b['gender'] ?? ''));
      } else if (sortBy == 'culture') {
        filteredCharacters.sort((a, b) => (a['culture'] ?? '').compareTo(b['culture'] ?? ''));
      }
    });
  }

  void toggleFavorite(character) {
    setState(() {
      if (favorites.contains(character)) {
        favorites.remove(character);
      } else {
        favorites.add(character);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Character Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortBy = value;
                applySorting();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'gender', child: Text('Sort by Gender')),
              PopupMenuItem(value: 'culture', child: Text('Sort by Culture')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                  labelText: 'Search by Name',
                  border: OutlineInputBorder()),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                  filteredCharacters = characters
                      .where((c) => c['name']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()))
                      .toList();
                  applySorting();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCharacters.length,
              itemBuilder: (context, index) {
                final character = filteredCharacters[index];
                final name = character['name']?.isNotEmpty == true
                    ? character['name']
                    : 'Unnamed Character';
                return ListTile(
                  title: Text(name),
                  subtitle: Text(
                      'Gender: ${character['gender'] ?? 'Unknown'}, Culture: ${character['culture'] ?? 'Unknown'}'),
                  trailing: IconButton(
                    icon: Icon(
                      favorites.contains(character)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: favorites.contains(character)
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: () => toggleFavorite(character),
                  ),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CharacterDetailView(character))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterDetailView extends StatelessWidget {
  final dynamic character;
  CharacterDetailView(this.character);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character['name'] ?? 'Character Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${character['name'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 22)),
            SizedBox(height: 10),
            Text('Gender: ${character['gender'] ?? 'Unknown'}'),
            Text('Culture: ${character['culture'] ?? 'Unknown'}'),
            Text('Aliases: ${character['aliases']?.join(', ') ?? 'None'}'),
            Text('Titles: ${character['titles']?.join(', ') ?? 'None'}'),
            Text('Books: ${character['books']?.join(', ') ?? 'None'}'),
          ],
        ),
      ),
    );
  }
}

class ApiService {
  static const baseUrl = 'https://anapioficeandfire.com/api';

  static Future<List<dynamic>> getAllCharacters() async {
    List<dynamic> allCharacters = [];
    int page = 1;
    bool moreData = true;

    while (moreData) {
      final response = await http
          .get(Uri.parse('$baseUrl/characters?page=$page&pageSize=50'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          allCharacters.addAll(data);
          page++;
        } else {
          moreData = false;
        }
      } else {
        throw Exception('Failed to load characters');
      }
    }
    return allCharacters;
  }
}

class GuessGameScreen extends StatefulWidget {
  @override
  _GuessGameScreenState createState() => _GuessGameScreenState();
}

class _GuessGameScreenState extends State<GuessGameScreen> {
  List characters = [];
  List<String> characterNames = [];
  String answer = '';
  String feedback = '';
  String hint = '';
  int attempts = 0;
  String currentGuess = '';
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    loadCharacters();
  }

  Future<void> loadCharacters() async {
    try {
      final fetchedCharacters = await ApiService.getAllCharacters();
      setState(() {
        characters = fetchedCharacters;
        characterNames = characters
            .map((c) => c['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      });
    } catch (e) {
      print('Error fetching characters: $e');
    }
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      selectRandomAnswer();
    });
  }
  String generateHint() {
    if (answer.isEmpty) return '';
    int revealedLength = (attempts + 1).clamp(1, answer.length ~/ 2);
    return answer.substring(0, revealedLength) +
        ''.padRight(answer.length - revealedLength, '*');
  }
  void selectRandomAnswer() {
    setState(() {
      answer = (characterNames..shuffle()).first;
      hint = generateHint();
      attempts = 0;
      feedback = '';
      currentGuess = '';
    });
  }

  void checkGuess() {
    setState(() {
      if (currentGuess.toLowerCase() == answer.toLowerCase()) {
        feedback = 'Correct!';
      } else {
        feedback = 'Try again!';
        attempts++;
        hint = generateHint();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guess the Character')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: gameStarted
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guess the Character Name:',
                style: Theme.of(context).textTheme.displayLarge),
            SizedBox(height: 20),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text == '') {
                  return const Iterable<String>.empty();
                }
                return characterNames.where((name) => name
                    .toLowerCase()
                    .contains(value.text.toLowerCase()));
              },
              onSelected: (value) => setState(() {
                currentGuess = value;
              }),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: currentGuess.isNotEmpty ? checkGuess : null,
              child: Text('Confirm Your Answer'),
            ),
            SizedBox(height: 20),
            Text('Hint: $hint', style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 20),
            Text(feedback, style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectRandomAnswer,
              child: Text('Generate Character'),
            ),
          ],
        )
            : Center(
          child: ElevatedButton(
            onPressed: startGame,
            child: Text('Start Game'),
          ),
        ),
      ),
    );
  }
}
