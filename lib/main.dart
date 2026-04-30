import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ListUserDataPage());
  }
}

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database?> _initDB() async {
    String path = p.join(await getDatabasesPath(), "user_db.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, umur INTEGER)",
        );
      },
    );
  }

  //create
  static Future<int> insertData(UserModel userModel) async {
    final db = await database;
    Map<String, dynamic> user = userModel.toJson();

    return await db.insert(
      "users",
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //read
  static Future<List<UserModel>> getData() async {
    final db = await database;
    List<Map<String, Object?>> result = await db.query("users");

    List<UserModel> users = result.map((userMap) {
      return UserModel.fromJson(userMap);
    }).toList();
    return users;
  }

  //update
  static Future<int> updateData(int id, UserModel userModel) async {
    final db = await database;
    var user = userModel.toJson()..remove("id");

    return await db.update("users", user, where: "id = ?", whereArgs: [id]);
  }

  //delete
  static Future<int> deleteData(int id) async {
    final db = await database;
    return await db.delete("users", where: "id = ?", whereArgs: [id]);
  }
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class UserModel {
  int? id;
  String nama = "";
  int umur = 0;

  UserModel(this.id, {required this.nama, required this.umur});

  //convert dari map /hashmap ke model

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(json["id"], nama: json["nama"], umur: json["umur"]);
  }

  //convert dari model ke map

  Map<String, dynamic> toJson() {
    return {"id": id, "nama": nama, "umur": umur};
  }
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _umurCtrl = TextEditingController();

  List<UserModel> userList = [];

  @override
  void initState() {
    super.initState();

    _reloadData();
  }

  void _reloadData() async {
    var users = await DatabaseHelper.getData();

    setState(() {
      userList = users;
    });
  }

  void _form(int? id) {
    if (id != null) {
      var user = userList.firstWhere((data) => data.id == id);
      _nameCtrl.text = user.nama;
      _umurCtrl.text = user.umur.toString();
    } else {
      _nameCtrl.clear();
      _umurCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsetsGeometry.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(hintText: "Nama"),
            ),
            TextField(
              controller: _umurCtrl,
              decoration: InputDecoration(hintText: "Umur"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () =>
                  _save(id, _nameCtrl.text, int.parse(_umurCtrl.text)),
              child: Text(id == null ? "Tambah" : "perbarui"),
            ),
          ],
        ),
      ),
    );
  }

  void _save(int? id, String nama, int umur) async {
    var newUser = UserModel(null, nama: nama, umur: umur);
    if (id != null) {
      await DatabaseHelper.updateData(id, newUser);
    } else {
      await DatabaseHelper.insertData(newUser);
    }

    _reloadData();
    Navigator.pop(context);
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("konfirmasi hapus"),
        content: Text("apakah anda yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("batal"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.deleteData(id);
              _reloadData();
              Navigator.pop(context);
            },
            child: Text("hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User List")),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(userList[i].nama),
          subtitle: Text("umur: ${userList[i].umur} tahun"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _form(userList[i].id),
                child: const Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () => _delete(userList[i].id!),
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
