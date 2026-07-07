// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TableEventModelAdapter extends TypeAdapter<TableEventModel> {
  @override
  final typeId = 3;

  @override
  TableEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TableEventModel(
      id: fields[0] as String,
      tableId: fields[1] as String,
      memberId: fields[2] as String,
      memberName: fields[3] as String,
      type: fields[4] as String,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TableEventModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tableId)
      ..writeByte(2)
      ..write(obj.memberId)
      ..writeByte(3)
      ..write(obj.memberName)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
