BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS `version` (
	`version`	INTEGER DEFAULT 1
);
INSERT INTO `version` VALUES (7);
CREATE TABLE IF NOT EXISTS `tracks` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`track`	INTEGER DEFAULT 0,
	`disc`	TEXT DEFAULT '1',
	`bpm`	REAL DEFAULT 0,
	`duration`	INTEGER DEFAULT 0,
	`filesize`	INTEGER DEFAULT 0,
	`visual_genre_id`	INTEGER DEFAULT 0,
	`visual_artist_id`	INTEGER DEFAULT 0,
	`album_artist_id`	INTEGER DEFAULT 0,
	`path_id`	INTEGER,
	`album_id`	INTEGER DEFAULT 0,
	`title`	TEXT DEFAULT '',
	`filename`	TEXT DEFAULT '',
	`filetime`	INTEGER DEFAULT 0,
	`thumbnail_id`	INTEGER DEFAULT 0,
	`source_id`	INTEGER DEFAULT 0,
	`visible`	INTEGER DEFAULT 1,
	`external_id`	TEXT DEFAULT null
);
CREATE TABLE IF NOT EXISTS `track_meta` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`track_id`	INTEGER DEFAULT 0,
	`meta_value_id`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `track_genres` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`track_id`	INTEGER DEFAULT 0,
	`genre_id`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `track_artists` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`track_id`	INTEGER DEFAULT 0,
	`artist_id`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `thumbnails` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`filename`	TEXT DEFAULT '',
	`filesize`	INTEGER DEFAULT 0,
	`checksum`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `replay_gain` (
	`id`	INTEGER,
	`track_id`	INTEGER DEFAULT 0,
	`album_gain`	REAL DEFAULT 1.0,
	`album_peak`	REAL DEFAULT 1.0,
	`track_gain`	REAL DEFAULT 1.0,
	`track_peak`	REAL DEFAULT 1.0,
	PRIMARY KEY(`id`)
);
CREATE TABLE IF NOT EXISTS `playlists` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`name`	TEXT DEFAULT '',
	`user_id`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `playlist_tracks` (
	`playlist_id`	INTEGER DEFAULT 0,
	`track_external_id`	TEXT NOT NULL DEFAULT '',
	`source_id`	INTEGER DEFAULT 0,
	`sort_order`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `paths` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`path`	TEXT DEFAULT ''
);
INSERT INTO `paths` VALUES (1,'/music/');
CREATE TABLE IF NOT EXISTS `meta_values` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`meta_key_id`	INTEGER DEFAULT 0,
	`sort_order`	INTEGER DEFAULT 0,
	`content`	TEXT
);
CREATE TABLE IF NOT EXISTS `meta_keys` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`name`	TEXT
);
CREATE TABLE IF NOT EXISTS `genres` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`name`	TEXT DEFAULT '',
	`aggregated`	INTEGER DEFAULT 0,
	`sort_order`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `artists` (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`name`	TEXT DEFAULT '',
	`aggregated`	INTEGER DEFAULT 0,
	`sort_order`	INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `albums` (
	`id`	INTEGER,
	`name`	TEXT DEFAULT '',
	`thumbnail_id`	INTEGER DEFAULT 0,
	`sort_order`	INTEGER DEFAULT 0,
	PRIMARY KEY(`id`)
);
CREATE INDEX IF NOT EXISTS `tracks_external_id_index` ON `tracks` (
	`external_id`
);
CREATE INDEX IF NOT EXISTS `trackmeta_index2` ON `track_meta` (
	`meta_value_id`,
	`track_id`
);
CREATE INDEX IF NOT EXISTS `trackmeta_index1` ON `track_meta` (
	`track_id`,
	`meta_value_id`
);
CREATE INDEX IF NOT EXISTS `trackgenre_index2` ON `track_genres` (
	`genre_id`,
	`track_id`
);
CREATE INDEX IF NOT EXISTS `trackgenre_index1` ON `track_genres` (
	`track_id`,
	`genre_id`
);
CREATE INDEX IF NOT EXISTS `trackartist_index2` ON `track_artists` (
	`artist_id`,
	`track_id`
);
CREATE INDEX IF NOT EXISTS `trackartist_index1` ON `track_artists` (
	`track_id`,
	`artist_id`
);
CREATE INDEX IF NOT EXISTS `thumbnail_index` ON `thumbnails` (
	`filesize`
);
CREATE INDEX IF NOT EXISTS `playlist_tracks_index_3` ON `playlist_tracks` (
	`track_external_id`
);
CREATE INDEX IF NOT EXISTS `playlist_tracks_index_2` ON `playlist_tracks` (
	`track_external_id`,
	`sort_order`
);
CREATE INDEX IF NOT EXISTS `playlist_tracks_index_1` ON `playlist_tracks` (
	`track_external_id`,
	`playlist_id`,
	`sort_order`
);
CREATE INDEX IF NOT EXISTS `paths_index` ON `paths` (
	`path`
);
CREATE INDEX IF NOT EXISTS `metavalues_index4` ON `meta_values` (
	`id`,
	`content`
);
CREATE INDEX IF NOT EXISTS `metavalues_index3` ON `meta_values` (
	`id`,
	`meta_key_id`,
	`content`
);
CREATE INDEX IF NOT EXISTS `metavalues_index2` ON `meta_values` (
	`content`
);
CREATE INDEX IF NOT EXISTS `metavalues_index1` ON `meta_values` (
	`meta_key_id`
);
CREATE INDEX IF NOT EXISTS `metakey_index2` ON `meta_keys` (
	`id`,
	`name`
);
CREATE INDEX IF NOT EXISTS `metakey_index1` ON `meta_keys` (
	`name`
);
CREATE INDEX IF NOT EXISTS `genre_index` ON `genres` (
	`sort_order`
);
CREATE INDEX IF NOT EXISTS `artist_index` ON `artists` (
	`sort_order`
);
CREATE INDEX IF NOT EXISTS `album_index` ON `albums` (
	`sort_order`
);
CREATE VIEW tracks_view AS SELECT DISTINCT  t.id, t.track, t.disc, t.bpm, t.duration, t.filesize, t.title, t.filename,  t.thumbnail_id, t.external_id, al.name AS album, alar.name AS album_artist, gn.name AS genre,  ar.name AS artist, t.filetime, t.visual_genre_id, t.visual_artist_id, t.album_artist_id, t.album_id FROM  tracks t, albums al, artists alar, artists ar, genres gn WHERE  t.album_id=al.id AND t.album_artist_id=alar.id AND  t.visual_genre_id=gn.id AND t.visual_artist_id=ar.id;
CREATE VIEW extended_metadata AS SELECT DISTINCT tracks.id, tracks.external_id, tracks.source_id, meta_keys.id AS meta_key_id, track_meta.meta_value_id, meta_keys.name AS key, meta_values.content AS value FROM track_meta, meta_values, meta_keys, tracks WHERE tracks.id == track_meta.track_id AND meta_values.id = track_meta.meta_value_id AND meta_values.meta_key_id == meta_keys.id;
COMMIT;
