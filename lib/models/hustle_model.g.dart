// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hustle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HustleAdapter extends TypeAdapter<Hustle> {
  @override
  final int typeId = 0;

  @override
  Hustle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hustle(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime,
      totalEarnings: fields[4] as double?,
      currency: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Hustle obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.totalEarnings)
      ..writeByte(5)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HustleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
