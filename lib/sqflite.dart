// ignore_for_file: unnecessary_null_comparison, non_constant_identifier_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'globals.dart' as globals;

// database table and column names
const String tablePositions = 'positions';
const String columnid = 'id';
const String columnDate = 'Date';
const String columnSpeed = 'speed';
const String columnLongtitude = 'Longtitude';
const String columnLatitude = 'Latitude';
const String columnAltitude = 'Altitude';
const String columnDistance = 'distance';

// data model class ie le type qui décrit une position
class Position {
  int id = 0;
  String Date = "";
  String speed = "0.00";
  String Longtitude = "0.0";
  String Latitude = "0.0";
  String Altitude = "0.00" ;
  String distance = "0.00";
  
  Position();
  
  // convenience constructor to create a Position object
  // ignore: empty_constructor_bodies
  Position.fromMap(Map<String, dynamic> map) {
    Date = map[columnDate];
    speed = map[columnSpeed];
    Longtitude = map[columnLongtitude];
    Latitude = map[columnLatitude];
    Altitude = map[columnAltitude];
    distance = map[columnDistance];

  }
  
  // convenience method to create a Map from this Position object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnid: id,
      columnDate: Date,
      columnSpeed: speed,
      columnLongtitude: Longtitude,
      columnLatitude: Latitude,
      columnAltitude: Altitude,
      columnDistance: distance
    };
    return map;
  }
}

// singleton class to manage the database
class DatabaseHelper {
  DatabaseHelper();
  // This is the actual database filename that is saved in the docs directory.
  static const _databaseName = "MyDatabase.db";
  // Increment this version when you need to change the schema.
  static const _databaseVersion = 1;
  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  
  // Only allow a single open connection to the database.
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null){
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }
  
  // open the database
 Future _initDatabase() async {

    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
      version: _databaseVersion,
      onCreate: _onCreate
    );
  }
  
  // SQL string to create the database 
  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePositions (
        $columnid NUMBER,
        $columnDate DATE,
        $columnSpeed VARCHAR2(10) NOT NULL,
        $columnLongtitude VARCHAR2(15) NOT NULL,
        $columnLatitude VARCHAR2(15) NOT NULL,
        $columnAltitude VARCHAR2(15) NOT NULL,
        $columnDistance VARCHAR2(15) NOT NULL
      )
    ''');
  }
  
  // Database helper methods:
  Future<int> insert(Position Position) async { 
    final _db = await instance.database;
    debugPrint("hellos");
    return await _db.insert(tablePositions, Position.toMap());
  }
  
  // Query All positions available in the local database
  Future<List<Position>?> queryPosition() async {
    Database db = await instance.database;
    final maps = await db.query(tablePositions, where: "$columnid = ?", whereArgs: [globals.identifiant], 
      orderBy: '$columnDate ASC');
    if (maps.isNotEmpty) {
      return maps.map((map) => Position.fromMap(map)).toList();
    }
    return [];
  }
  
}