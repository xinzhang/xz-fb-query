import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pets',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Please register your pet',
                  style: TextStyle(
                      fontWeight: FontWeight.w200,
                      fontSize: 30,
                      fontFamily: 'Roboto',
                      fontStyle: FontStyle.italic)),
              RegisterPet(),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPet extends StatefulWidget {
  RegisterPet({Key key}) : super(key: key);

  @override
  _RegisterPetState createState() => _RegisterPetState();
}

class _RegisterPetState extends State<RegisterPet> {
  final _formKey = GlobalKey<FormState>();
  final listOfPets = ["Cats", "Dogs", "Rabbits"];
  String dropdownValue = 'Cats';

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final dbRef = FirebaseFirestore.instance.collection("pets");

  void handleSubmit() {
    if (_formKey.currentState.validate()) {
      dbRef.add({
        "name": nameController.text,
        "age": ageController.text,
        "type": dropdownValue
      }).then((_) {
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Successfully Added')));
        ageController.clear();
        nameController.clear();
      }).catchError((onError) {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(onError)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            Padding(
              padding: EdgeInsets.all(20.0),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: "Enter pet name",
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Enter Pet Name';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: DropdownButtonFormField(
                value: dropdownValue,
                icon: Icon(Icons.arrow_downward),
                decoration: InputDecoration(
                    labelText: "Select pet type",
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0))),
                items: listOfPets.map((String value) {
                  return new DropdownMenuItem<String>(
                      value: value, child: new Text(value));
                }).toList(),
                onChanged: (String newValue) {
                  setState(() {
                    dropdownValue = newValue;
                  });
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please Select Pet';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: ageController,
                decoration: InputDecoration(
                  labelText: "Enter Pet Age",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                // The validator receives the text that the user has entered.
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please Pet Age';
                  }
                  return null;
                },
              ),
            ),
            Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    RaisedButton(
                      color: Colors.lightBlue,
                      onPressed: handleSubmit,
                      child: Text('Submit'),
                    ),
                    RaisedButton(
                      color: Colors.amber,
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Home()));
                      },
                      child: Text('Navigate'),
                    ),
                  ],
                ))
          ]),
        ));
  }

  @override
  void dispose() {
    super.dispose();
    ageController.dispose();
    nameController.dispose();
  }
}

class Home extends StatelessWidget {
  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic> data = document.data();
    return Container(
        padding: const EdgeInsets.all(16.0),
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: " + data['name']),
            Text("Age: " + data['age']),
            Text("Type: " + data['type']),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => RegisterPet()));
              },
            )
          ],
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection("pets")
              .orderBy('name')
              //.where('age', isGreaterThan: 5)
              .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text("Loading Data ...");
              }
              return ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) =>
                      _buildListItem(context, snapshot.data.documents[index]));
            }));
  }
}
