// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_summary.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEventSummaryCollection on Isar {
  IsarCollection<EventSummary> get eventSummarys => this.collection();
}

const EventSummarySchema = CollectionSchema(
  name: r'EventSummary',
  id: -8272051165521313849,
  properties: {
    r'eventCount': PropertySchema(
      id: 0,
      name: r'eventCount',
      type: IsarType.long,
    ),
    r'eventName': PropertySchema(
      id: 1,
      name: r'eventName',
      type: IsarType.string,
    ),
    r'lastSeen': PropertySchema(
      id: 2,
      name: r'lastSeen',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _eventSummaryEstimateSize,
  serialize: _eventSummarySerialize,
  deserialize: _eventSummaryDeserialize,
  deserializeProp: _eventSummaryDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventName': IndexSchema(
      id: 7994041348978878758,
      name: r'eventName',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'eventName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _eventSummaryGetId,
  getLinks: _eventSummaryGetLinks,
  attach: _eventSummaryAttach,
  version: '3.1.0+1',
);

int _eventSummaryEstimateSize(
  EventSummary object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventName.length * 3;
  return bytesCount;
}

void _eventSummarySerialize(
  EventSummary object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.eventCount);
  writer.writeString(offsets[1], object.eventName);
  writer.writeDateTime(offsets[2], object.lastSeen);
}

EventSummary _eventSummaryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EventSummary();
  object.eventCount = reader.readLong(offsets[0]);
  object.eventName = reader.readString(offsets[1]);
  object.id = id;
  object.lastSeen = reader.readDateTime(offsets[2]);
  return object;
}

P _eventSummaryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _eventSummaryGetId(EventSummary object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _eventSummaryGetLinks(EventSummary object) {
  return [];
}

void _eventSummaryAttach(
    IsarCollection<dynamic> col, Id id, EventSummary object) {
  object.id = id;
}

extension EventSummaryByIndex on IsarCollection<EventSummary> {
  Future<EventSummary?> getByEventName(String eventName) {
    return getByIndex(r'eventName', [eventName]);
  }

  EventSummary? getByEventNameSync(String eventName) {
    return getByIndexSync(r'eventName', [eventName]);
  }

  Future<bool> deleteByEventName(String eventName) {
    return deleteByIndex(r'eventName', [eventName]);
  }

  bool deleteByEventNameSync(String eventName) {
    return deleteByIndexSync(r'eventName', [eventName]);
  }

  Future<List<EventSummary?>> getAllByEventName(List<String> eventNameValues) {
    final values = eventNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventName', values);
  }

  List<EventSummary?> getAllByEventNameSync(List<String> eventNameValues) {
    final values = eventNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventName', values);
  }

  Future<int> deleteAllByEventName(List<String> eventNameValues) {
    final values = eventNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventName', values);
  }

  int deleteAllByEventNameSync(List<String> eventNameValues) {
    final values = eventNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventName', values);
  }

  Future<Id> putByEventName(EventSummary object) {
    return putByIndex(r'eventName', object);
  }

  Id putByEventNameSync(EventSummary object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventName(List<EventSummary> objects) {
    return putAllByIndex(r'eventName', objects);
  }

  List<Id> putAllByEventNameSync(List<EventSummary> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventName', objects, saveLinks: saveLinks);
  }
}

extension EventSummaryQueryWhereSort
    on QueryBuilder<EventSummary, EventSummary, QWhere> {
  QueryBuilder<EventSummary, EventSummary, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EventSummaryQueryWhere
    on QueryBuilder<EventSummary, EventSummary, QWhereClause> {
  QueryBuilder<EventSummary, EventSummary, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterWhereClause> eventNameEqualTo(
      String eventName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventName',
        value: [eventName],
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterWhereClause>
      eventNameNotEqualTo(String eventName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventName',
              lower: [],
              upper: [eventName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventName',
              lower: [eventName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventName',
              lower: [eventName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventName',
              lower: [],
              upper: [eventName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension EventSummaryQueryFilter
    on QueryBuilder<EventSummary, EventSummary, QFilterCondition> {
  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventCount',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventCount',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventCount',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventName',
        value: '',
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      eventNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventName',
        value: '',
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      lastSeenEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      lastSeenGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      lastSeenLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterFilterCondition>
      lastSeenBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSeen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EventSummaryQueryObject
    on QueryBuilder<EventSummary, EventSummary, QFilterCondition> {}

extension EventSummaryQueryLinks
    on QueryBuilder<EventSummary, EventSummary, QFilterCondition> {}

extension EventSummaryQuerySortBy
    on QueryBuilder<EventSummary, EventSummary, QSortBy> {
  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> sortByEventCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCount', Sort.asc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy>
      sortByEventCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCount', Sort.desc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> sortByEventName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.asc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> sortByEventNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.desc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> sortByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> sortByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }
}

extension EventSummaryQuerySortThenBy
    on QueryBuilder<EventSummary, EventSummary, QSortThenBy> {
  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> thenByEventCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCount', Sort.asc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy>
      thenByEventCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventCount', Sort.desc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> thenByEventName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.asc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> thenByEventNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.desc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> thenByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QAfterSortBy> thenByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }
}

extension EventSummaryQueryWhereDistinct
    on QueryBuilder<EventSummary, EventSummary, QDistinct> {
  QueryBuilder<EventSummary, EventSummary, QDistinct> distinctByEventCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventCount');
    });
  }

  QueryBuilder<EventSummary, EventSummary, QDistinct> distinctByEventName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventSummary, EventSummary, QDistinct> distinctByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSeen');
    });
  }
}

extension EventSummaryQueryProperty
    on QueryBuilder<EventSummary, EventSummary, QQueryProperty> {
  QueryBuilder<EventSummary, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EventSummary, int, QQueryOperations> eventCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventCount');
    });
  }

  QueryBuilder<EventSummary, String, QQueryOperations> eventNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventName');
    });
  }

  QueryBuilder<EventSummary, DateTime, QQueryOperations> lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSeen');
    });
  }
}
