/// filter is a JSON object that determines what events will be sent in that subscription
class Filter {
  /// a list of event ids or prefixes
  List<String>? ids;

  /// a list of pubkeys or prefixes, the pubkey of an event must be one of these
  List<String>? authors;

  /// a list of pubkeys or prefixes, the pubkey of an event must be one of these
  List<String>? author;

  /// a list of a kind numbers
  List<int>? kinds;

  /// a list of event ids that are referenced in an "e" tag
  List<String>? e;

  /// a list of event ids that are referenced in an "l" tag
  List<String>? l;

  /// a list of pubkeys that are referenced in a "p" tag
  List<String>? p;

  /// a list of identifiers that are referenced in a "d" tag
  List<String>? d;

  /// a list of identifiers that are referenced in a "c" tag
  List<String>? c;

  /// a list of identifiers that are referenced in a "a" tag
  List<String>? a;

  /// a list of identifiers that are referenced in a "q" tag
  List<String>? q;

  /// a list of identifiers that are referenced in a "t" tag
  List<String>? t;

  /// a timestamp, events must be newer than this to pass
  int? since;

  /// a timestamp, events must be older than this to pass
  int? until;

  /// maximum number of events to be returned in the initial query
  int? limit;

  /// Default constructor
  Filter({
    this.ids,
    this.authors,
    this.author,
    this.kinds,
    this.e,
    this.p,
    this.l,
    this.d,
    this.c,
    this.a,
    this.t,
    this.q,
    this.since,
    this.until,
    this.limit,
  });

  /// Deserialize a filter from a JSON
  Filter.fromJson(Map<String, dynamic> json) {
    ids = json['ids'] == null ? null : List<String>.from(json['ids']);
    authors =
        json['authors'] == null ? null : List<String>.from(json['authors']);
    author = json['author'] == null ? null : List<String>.from(json['author']);
    kinds = json['kinds'] == null ? null : List<int>.from(json['kinds']);
    e = json['#e'] == null ? null : List<String>.from(json['#e']);
    p = json['#p'] == null ? null : List<String>.from(json['#p']);
    d = json['#d'] == null ? null : List<String>.from(json['#d']);
    c = json['#c'] == null ? null : List<String>.from(json['#c']);
    a = json['#a'] == null ? null : List<String>.from(json['#a']);
    t = json['#t'] == null ? null : List<String>.from(json['#t']);
    l = json['#l'] == null ? null : List<String>.from(json['#l']);
    q = json['#q'] == null ? null : List<String>.from(json['#q']);
    since = json['since'];
    until = json['until'];
    limit = json['limit'];
  }

  /// Serialize a filter in JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (ids != null) {
      data['ids'] = ids;
    }
    if (authors != null) {
      data['authors'] = authors;
    }

    if (kinds != null) {
      data['kinds'] = kinds;
    }
    if (author != null) {
      data['#author'] = author;
    }
    if (e != null) {
      data['#e'] = e;
    }
    if (l != null) {
      data['#l'] = l;
    }
    if (p != null) {
      data['#p'] = p;
    }
    if (d != null) {
      data['#d'] = d;
    }
    if (c != null) {
      data['#c'] = c;
    }
    if (a != null) {
      data['#a'] = a;
    }
    if (t != null) {
      data['#t'] = t;
    }
    if (q != null) {
      data['#q'] = q;
    }
    if (since != null) {
      data['since'] = since;
    }
    if (until != null) {
      data['until'] = until;
    }
    if (limit != null) {
      data['limit'] = limit;
    }

    return data;
  }
}
