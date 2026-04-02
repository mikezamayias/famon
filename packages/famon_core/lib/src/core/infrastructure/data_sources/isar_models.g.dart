// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAnalyticsEventCollection on Isar {
  IsarCollection<IsarAnalyticsEvent> get isarAnalyticsEvents =>
      this.collection();
}

const IsarAnalyticsEventSchema = CollectionSchema(
  name: r'IsarAnalyticsEvent',
  id: 3184369647616688735,
  properties: {
    r'domainId': PropertySchema(
      id: 0,
      name: r'domainId',
      type: IsarType.string,
    ),
    r'eventName': PropertySchema(
      id: 1,
      name: r'eventName',
      type: IsarType.string,
    ),
    r'isFiltered': PropertySchema(
      id: 2,
      name: r'isFiltered',
      type: IsarType.bool,
    ),
    r'itemsJson': PropertySchema(
      id: 3,
      name: r'itemsJson',
      type: IsarType.string,
    ),
    r'manualParametersJson': PropertySchema(
      id: 4,
      name: r'manualParametersJson',
      type: IsarType.string,
    ),
    r'parametersJson': PropertySchema(
      id: 5,
      name: r'parametersJson',
      type: IsarType.string,
    ),
    r'sessionId': PropertySchema(
      id: 6,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 7,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarAnalyticsEventEstimateSize,
  serialize: _isarAnalyticsEventSerialize,
  deserialize: _isarAnalyticsEventDeserialize,
  deserializeProp: _isarAnalyticsEventDeserializeProp,
  idName: r'id',
  indexes: {
    r'domainId': IndexSchema(
      id: -9138809277110658179,
      name: r'domainId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'domainId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'eventName': IndexSchema(
      id: 7994041348978878758,
      name: r'eventName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarAnalyticsEventGetId,
  getLinks: _isarAnalyticsEventGetLinks,
  attach: _isarAnalyticsEventAttach,
  version: '3.1.0+1',
);

int _isarAnalyticsEventEstimateSize(
  IsarAnalyticsEvent object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.domainId.length * 3;
  bytesCount += 3 + object.eventName.length * 3;
  bytesCount += 3 + object.itemsJson.length * 3;
  bytesCount += 3 + object.manualParametersJson.length * 3;
  bytesCount += 3 + object.parametersJson.length * 3;
  {
    final value = object.sessionId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarAnalyticsEventSerialize(
  IsarAnalyticsEvent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.domainId);
  writer.writeString(offsets[1], object.eventName);
  writer.writeBool(offsets[2], object.isFiltered);
  writer.writeString(offsets[3], object.itemsJson);
  writer.writeString(offsets[4], object.manualParametersJson);
  writer.writeString(offsets[5], object.parametersJson);
  writer.writeString(offsets[6], object.sessionId);
  writer.writeDateTime(offsets[7], object.timestamp);
}

IsarAnalyticsEvent _isarAnalyticsEventDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAnalyticsEvent();
  object.domainId = reader.readString(offsets[0]);
  object.eventName = reader.readString(offsets[1]);
  object.id = id;
  object.isFiltered = reader.readBool(offsets[2]);
  object.itemsJson = reader.readString(offsets[3]);
  object.manualParametersJson = reader.readString(offsets[4]);
  object.parametersJson = reader.readString(offsets[5]);
  object.sessionId = reader.readStringOrNull(offsets[6]);
  object.timestamp = reader.readDateTime(offsets[7]);
  return object;
}

P _isarAnalyticsEventDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAnalyticsEventGetId(IsarAnalyticsEvent object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAnalyticsEventGetLinks(
    IsarAnalyticsEvent object) {
  return [];
}

void _isarAnalyticsEventAttach(
    IsarCollection<dynamic> col, Id id, IsarAnalyticsEvent object) {
  object.id = id;
}

extension IsarAnalyticsEventQueryWhereSort
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QWhere> {
  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhere>
      anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension IsarAnalyticsEventQueryWhere
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QWhereClause> {
  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      domainIdEqualTo(String domainId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'domainId',
        value: [domainId],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      domainIdNotEqualTo(String domainId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [],
              upper: [domainId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [domainId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [domainId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [],
              upper: [domainId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      eventNameEqualTo(String eventName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventName',
        value: [eventName],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarAnalyticsEventQueryFilter
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QFilterCondition> {
  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'domainId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'domainId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      domainIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'domainId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      eventNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      eventNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      eventNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      eventNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      isFilteredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFiltered',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      itemsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manualParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'manualParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'manualParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'manualParametersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'manualParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'manualParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'manualParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'manualParametersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manualParametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      manualParametersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'manualParametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parametersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parametersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      parametersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sessionId',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sessionId',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarAnalyticsEventQueryObject
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QFilterCondition> {}

extension IsarAnalyticsEventQueryLinks
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QFilterCondition> {}

extension IsarAnalyticsEventQuerySortBy
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QSortBy> {
  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByDomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByDomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByEventName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByEventNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByIsFiltered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiltered', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByIsFilteredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiltered', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByManualParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualParametersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByManualParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualParametersJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension IsarAnalyticsEventQuerySortThenBy
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QSortThenBy> {
  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByDomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByDomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByEventName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByEventNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByIsFiltered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiltered', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByIsFilteredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiltered', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByManualParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualParametersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByManualParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualParametersJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension IsarAnalyticsEventQueryWhereDistinct
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct> {
  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctByDomainId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'domainId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctByEventName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctByIsFiltered() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFiltered');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctByItemsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctByManualParametersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manualParametersJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctByParametersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parametersJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctBySessionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension IsarAnalyticsEventQueryProperty
    on QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QQueryProperty> {
  QueryBuilder<IsarAnalyticsEvent, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, String, QQueryOperations>
      domainIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'domainId');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, String, QQueryOperations>
      eventNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventName');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, bool, QQueryOperations>
      isFilteredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFiltered');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, String, QQueryOperations>
      itemsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemsJson');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, String, QQueryOperations>
      manualParametersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualParametersJson');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, String, QQueryOperations>
      parametersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parametersJson');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, String?, QQueryOperations>
      sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<IsarAnalyticsEvent, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarEventMetadataCollection on Isar {
  IsarCollection<IsarEventMetadata> get isarEventMetadatas => this.collection();
}

const IsarEventMetadataSchema = CollectionSchema(
  name: r'IsarEventMetadata',
  id: 3102438988136589853,
  properties: {
    r'averageParameterCount': PropertySchema(
      id: 0,
      name: r'averageParameterCount',
      type: IsarType.long,
    ),
    r'commonParametersJson': PropertySchema(
      id: 1,
      name: r'commonParametersJson',
      type: IsarType.string,
    ),
    r'customTags': PropertySchema(
      id: 2,
      name: r'customTags',
      type: IsarType.stringList,
    ),
    r'eventName': PropertySchema(
      id: 3,
      name: r'eventName',
      type: IsarType.string,
    ),
    r'firstSeen': PropertySchema(
      id: 4,
      name: r'firstSeen',
      type: IsarType.dateTime,
    ),
    r'frequency': PropertySchema(
      id: 5,
      name: r'frequency',
      type: IsarType.double,
    ),
    r'isHidden': PropertySchema(
      id: 6,
      name: r'isHidden',
      type: IsarType.bool,
    ),
    r'isWatched': PropertySchema(
      id: 7,
      name: r'isWatched',
      type: IsarType.bool,
    ),
    r'lastSeen': PropertySchema(
      id: 8,
      name: r'lastSeen',
      type: IsarType.dateTime,
    ),
    r'totalCount': PropertySchema(
      id: 9,
      name: r'totalCount',
      type: IsarType.long,
    )
  },
  estimateSize: _isarEventMetadataEstimateSize,
  serialize: _isarEventMetadataSerialize,
  deserialize: _isarEventMetadataDeserialize,
  deserializeProp: _isarEventMetadataDeserializeProp,
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
  getId: _isarEventMetadataGetId,
  getLinks: _isarEventMetadataGetLinks,
  attach: _isarEventMetadataAttach,
  version: '3.1.0+1',
);

int _isarEventMetadataEstimateSize(
  IsarEventMetadata object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.commonParametersJson.length * 3;
  bytesCount += 3 + object.customTags.length * 3;
  {
    for (var i = 0; i < object.customTags.length; i++) {
      final value = object.customTags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.eventName.length * 3;
  return bytesCount;
}

void _isarEventMetadataSerialize(
  IsarEventMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.averageParameterCount);
  writer.writeString(offsets[1], object.commonParametersJson);
  writer.writeStringList(offsets[2], object.customTags);
  writer.writeString(offsets[3], object.eventName);
  writer.writeDateTime(offsets[4], object.firstSeen);
  writer.writeDouble(offsets[5], object.frequency);
  writer.writeBool(offsets[6], object.isHidden);
  writer.writeBool(offsets[7], object.isWatched);
  writer.writeDateTime(offsets[8], object.lastSeen);
  writer.writeLong(offsets[9], object.totalCount);
}

IsarEventMetadata _isarEventMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarEventMetadata();
  object.averageParameterCount = reader.readLong(offsets[0]);
  object.commonParametersJson = reader.readString(offsets[1]);
  object.customTags = reader.readStringList(offsets[2]) ?? [];
  object.eventName = reader.readString(offsets[3]);
  object.firstSeen = reader.readDateTime(offsets[4]);
  object.frequency = reader.readDouble(offsets[5]);
  object.id = id;
  object.isHidden = reader.readBool(offsets[6]);
  object.isWatched = reader.readBool(offsets[7]);
  object.lastSeen = reader.readDateTime(offsets[8]);
  object.totalCount = reader.readLong(offsets[9]);
  return object;
}

P _isarEventMetadataDeserializeProp<P>(
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
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarEventMetadataGetId(IsarEventMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarEventMetadataGetLinks(
    IsarEventMetadata object) {
  return [];
}

void _isarEventMetadataAttach(
    IsarCollection<dynamic> col, Id id, IsarEventMetadata object) {
  object.id = id;
}

extension IsarEventMetadataByIndex on IsarCollection<IsarEventMetadata> {
  Future<IsarEventMetadata?> getByEventName(String eventName) {
    return getByIndex(r'eventName', [eventName]);
  }

  IsarEventMetadata? getByEventNameSync(String eventName) {
    return getByIndexSync(r'eventName', [eventName]);
  }

  Future<bool> deleteByEventName(String eventName) {
    return deleteByIndex(r'eventName', [eventName]);
  }

  bool deleteByEventNameSync(String eventName) {
    return deleteByIndexSync(r'eventName', [eventName]);
  }

  Future<List<IsarEventMetadata?>> getAllByEventName(
      List<String> eventNameValues) {
    final values = eventNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventName', values);
  }

  List<IsarEventMetadata?> getAllByEventNameSync(List<String> eventNameValues) {
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

  Future<Id> putByEventName(IsarEventMetadata object) {
    return putByIndex(r'eventName', object);
  }

  Id putByEventNameSync(IsarEventMetadata object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventName(List<IsarEventMetadata> objects) {
    return putAllByIndex(r'eventName', objects);
  }

  List<Id> putAllByEventNameSync(List<IsarEventMetadata> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventName', objects, saveLinks: saveLinks);
  }
}

extension IsarEventMetadataQueryWhereSort
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QWhere> {
  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarEventMetadataQueryWhere
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QWhereClause> {
  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhereClause>
      eventNameEqualTo(String eventName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventName',
        value: [eventName],
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterWhereClause>
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

extension IsarEventMetadataQueryFilter
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QFilterCondition> {
  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      averageParameterCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'averageParameterCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      averageParameterCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'averageParameterCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      averageParameterCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'averageParameterCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      averageParameterCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'averageParameterCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'commonParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'commonParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'commonParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'commonParametersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'commonParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'commonParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'commonParametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'commonParametersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'commonParametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      commonParametersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'commonParametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customTags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customTags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customTags',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customTags',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customTags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customTags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customTags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customTags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customTags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      customTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      eventNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      eventNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      eventNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      eventNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      firstSeenEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      firstSeenGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      firstSeenLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      firstSeenBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstSeen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      frequencyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      frequencyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      frequencyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      frequencyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      isHiddenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isHidden',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      isWatchedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isWatched',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      lastSeenEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
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

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      totalCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      totalCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      totalCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
      totalCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarEventMetadataQueryObject
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QFilterCondition> {}

extension IsarEventMetadataQueryLinks
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QFilterCondition> {}

extension IsarEventMetadataQuerySortBy
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QSortBy> {
  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByAverageParameterCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageParameterCount', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByAverageParameterCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageParameterCount', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByCommonParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commonParametersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByCommonParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commonParametersJson', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByEventName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByEventNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByFirstSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByIsWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWatched', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByIsWatchedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWatched', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      sortByTotalCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.desc);
    });
  }
}

extension IsarEventMetadataQuerySortThenBy
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QSortThenBy> {
  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByAverageParameterCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageParameterCount', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByAverageParameterCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageParameterCount', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByCommonParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commonParametersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByCommonParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commonParametersJson', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByEventName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByEventNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventName', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByFirstSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByIsWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWatched', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByIsWatchedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWatched', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.asc);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterSortBy>
      thenByTotalCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.desc);
    });
  }
}

extension IsarEventMetadataQueryWhereDistinct
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct> {
  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByAverageParameterCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'averageParameterCount');
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByCommonParametersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'commonParametersJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByCustomTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customTags');
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByEventName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstSeen');
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency');
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHidden');
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByIsWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isWatched');
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSeen');
    });
  }

  QueryBuilder<IsarEventMetadata, IsarEventMetadata, QDistinct>
      distinctByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCount');
    });
  }
}

extension IsarEventMetadataQueryProperty
    on QueryBuilder<IsarEventMetadata, IsarEventMetadata, QQueryProperty> {
  QueryBuilder<IsarEventMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarEventMetadata, int, QQueryOperations>
      averageParameterCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'averageParameterCount');
    });
  }

  QueryBuilder<IsarEventMetadata, String, QQueryOperations>
      commonParametersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'commonParametersJson');
    });
  }

  QueryBuilder<IsarEventMetadata, List<String>, QQueryOperations>
      customTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customTags');
    });
  }

  QueryBuilder<IsarEventMetadata, String, QQueryOperations>
      eventNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventName');
    });
  }

  QueryBuilder<IsarEventMetadata, DateTime, QQueryOperations>
      firstSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstSeen');
    });
  }

  QueryBuilder<IsarEventMetadata, double, QQueryOperations>
      frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<IsarEventMetadata, bool, QQueryOperations> isHiddenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHidden');
    });
  }

  QueryBuilder<IsarEventMetadata, bool, QQueryOperations> isWatchedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isWatched');
    });
  }

  QueryBuilder<IsarEventMetadata, DateTime, QQueryOperations>
      lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSeen');
    });
  }

  QueryBuilder<IsarEventMetadata, int, QQueryOperations> totalCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCount');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSessionDataCollection on Isar {
  IsarCollection<IsarSessionData> get isarSessionDatas => this.collection();
}

const IsarSessionDataSchema = CollectionSchema(
  name: r'IsarSessionData',
  id: -5327067597278779708,
  properties: {
    r'sessionDataJson': PropertySchema(
      id: 0,
      name: r'sessionDataJson',
      type: IsarType.string,
    ),
    r'sessionId': PropertySchema(
      id: 1,
      name: r'sessionId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarSessionDataEstimateSize,
  serialize: _isarSessionDataSerialize,
  deserialize: _isarSessionDataDeserialize,
  deserializeProp: _isarSessionDataDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarSessionDataGetId,
  getLinks: _isarSessionDataGetLinks,
  attach: _isarSessionDataAttach,
  version: '3.1.0+1',
);

int _isarSessionDataEstimateSize(
  IsarSessionData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.sessionDataJson.length * 3;
  bytesCount += 3 + object.sessionId.length * 3;
  return bytesCount;
}

void _isarSessionDataSerialize(
  IsarSessionData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.sessionDataJson);
  writer.writeString(offsets[1], object.sessionId);
}

IsarSessionData _isarSessionDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSessionData();
  object.id = id;
  object.sessionDataJson = reader.readString(offsets[0]);
  object.sessionId = reader.readString(offsets[1]);
  return object;
}

P _isarSessionDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSessionDataGetId(IsarSessionData object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSessionDataGetLinks(IsarSessionData object) {
  return [];
}

void _isarSessionDataAttach(
    IsarCollection<dynamic> col, Id id, IsarSessionData object) {
  object.id = id;
}

extension IsarSessionDataByIndex on IsarCollection<IsarSessionData> {
  Future<IsarSessionData?> getBySessionId(String sessionId) {
    return getByIndex(r'sessionId', [sessionId]);
  }

  IsarSessionData? getBySessionIdSync(String sessionId) {
    return getByIndexSync(r'sessionId', [sessionId]);
  }

  Future<bool> deleteBySessionId(String sessionId) {
    return deleteByIndex(r'sessionId', [sessionId]);
  }

  bool deleteBySessionIdSync(String sessionId) {
    return deleteByIndexSync(r'sessionId', [sessionId]);
  }

  Future<List<IsarSessionData?>> getAllBySessionId(
      List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'sessionId', values);
  }

  List<IsarSessionData?> getAllBySessionIdSync(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sessionId', values);
  }

  Future<int> deleteAllBySessionId(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sessionId', values);
  }

  int deleteAllBySessionIdSync(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sessionId', values);
  }

  Future<Id> putBySessionId(IsarSessionData object) {
    return putByIndex(r'sessionId', object);
  }

  Id putBySessionIdSync(IsarSessionData object, {bool saveLinks = true}) {
    return putByIndexSync(r'sessionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySessionId(List<IsarSessionData> objects) {
    return putAllByIndex(r'sessionId', objects);
  }

  List<Id> putAllBySessionIdSync(List<IsarSessionData> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'sessionId', objects, saveLinks: saveLinks);
  }
}

extension IsarSessionDataQueryWhereSort
    on QueryBuilder<IsarSessionData, IsarSessionData, QWhere> {
  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSessionDataQueryWhere
    on QueryBuilder<IsarSessionData, IsarSessionData, QWhereClause> {
  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhereClause>
      sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterWhereClause>
      sessionIdNotEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarSessionDataQueryFilter
    on QueryBuilder<IsarSessionData, IsarSessionData, QFilterCondition> {
  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionDataJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionDataJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionDataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionDataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }
}

extension IsarSessionDataQueryObject
    on QueryBuilder<IsarSessionData, IsarSessionData, QFilterCondition> {}

extension IsarSessionDataQueryLinks
    on QueryBuilder<IsarSessionData, IsarSessionData, QFilterCondition> {}

extension IsarSessionDataQuerySortBy
    on QueryBuilder<IsarSessionData, IsarSessionData, QSortBy> {
  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      sortBySessionDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionDataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      sortBySessionDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionDataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }
}

extension IsarSessionDataQuerySortThenBy
    on QueryBuilder<IsarSessionData, IsarSessionData, QSortThenBy> {
  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      thenBySessionDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionDataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      thenBySessionDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionDataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }
}

extension IsarSessionDataQueryWhereDistinct
    on QueryBuilder<IsarSessionData, IsarSessionData, QDistinct> {
  QueryBuilder<IsarSessionData, IsarSessionData, QDistinct>
      distinctBySessionDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionDataJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSessionData, IsarSessionData, QDistinct> distinctBySessionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarSessionDataQueryProperty
    on QueryBuilder<IsarSessionData, IsarSessionData, QQueryProperty> {
  QueryBuilder<IsarSessionData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSessionData, String, QQueryOperations>
      sessionDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionDataJson');
    });
  }

  QueryBuilder<IsarSessionData, String, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }
}
