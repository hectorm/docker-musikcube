BEGIN TRANSACTION;

CREATE TABLE `version` (
	`version` INTEGER DEFAULT 1
);
INSERT INTO `version` VALUES (9);

CREATE TABLE `tracks` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`track` INTEGER DEFAULT 0,
	`disc` TEXT DEFAULT '1',
	`bpm` REAL DEFAULT 0,
	`duration` INTEGER DEFAULT 0,
	`filesize` INTEGER DEFAULT 0,
	`visual_genre_id` INTEGER DEFAULT 0,
	`visual_artist_id` INTEGER DEFAULT 0,
	`album_artist_id` INTEGER DEFAULT 0,
	`path_id` INTEGER,
	`directory_id` INTEGER,
	`album_id` INTEGER DEFAULT 0,
	`title` TEXT DEFAULT '',
	`filename` TEXT DEFAULT '',
	`filetime` INTEGER DEFAULT 0,
	`thumbnail_id` INTEGER DEFAULT 0,
	`source_id` INTEGER DEFAULT 0,
	`visible` INTEGER DEFAULT 1,
	`external_id` TEXT DEFAULT NULL,
	`rating` INTEGER DEFAULT 0,
	`last_played` REAL DEFAULT NULL,
	`play_count` INTEGER DEFAULT 0,
	`date_added` REAL DEFAULT NULL,
	`date_updated` REAL DEFAULT NULL
);

CREATE TABLE `track_meta` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`track_id` INTEGER DEFAULT 0,
	`meta_value_id` INTEGER DEFAULT 0
);

CREATE TABLE `track_genres` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`track_id` INTEGER DEFAULT 0,
	`genre_id` INTEGER DEFAULT 0
);

CREATE TABLE `track_artists` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`track_id` INTEGER DEFAULT 0,
	`artist_id` INTEGER DEFAULT 0
);

CREATE TABLE `thumbnails` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`filename` TEXT DEFAULT '',
	`filesize` INTEGER DEFAULT 0,
	`checksum` INTEGER DEFAULT 0
);

CREATE TABLE `replay_gain` (
	`id` INTEGER,
	`track_id` INTEGER DEFAULT 0,
	`album_gain` REAL DEFAULT 1.0,
	`album_peak` REAL DEFAULT 1.0,
	`track_gain` REAL DEFAULT 1.0,
	`track_peak` REAL DEFAULT 1.0,
	PRIMARY KEY(`id`)
);

CREATE TABLE `playlists` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`name` TEXT DEFAULT '',
	`user_id` INTEGER DEFAULT 0
);

CREATE TABLE `playlist_tracks` (
	`playlist_id` INTEGER DEFAULT 0,
	`track_external_id` TEXT NOT NULL DEFAULT '',
	`source_id` INTEGER DEFAULT 0,
	`sort_order` INTEGER DEFAULT 0
);

CREATE TABLE `paths` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`path` TEXT DEFAULT ''
);
INSERT INTO `paths` VALUES (1, '/music/');

CREATE TABLE `meta_values` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`meta_key_id` INTEGER DEFAULT 0,
	`sort_order` INTEGER DEFAULT 0,
	`content` TEXT
);

CREATE TABLE `meta_keys` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`name` TEXT
);

CREATE TABLE `last_session_play_queue` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`track_id` INTEGER
);

CREATE TABLE `genres` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`name` TEXT DEFAULT '',
	`aggregated` INTEGER DEFAULT 0,
	`sort_order` INTEGER DEFAULT 0
);

CREATE TABLE `directories` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`name` TEXT NOT NULL
);

CREATE TABLE `artists` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`name` TEXT DEFAULT '',
	`aggregated` INTEGER DEFAULT 0,
	`sort_order` INTEGER DEFAULT 0
);

CREATE TABLE `albums` (
	`id` INTEGER,
	`name` TEXT DEFAULT '',
	`thumbnail_id` INTEGER DEFAULT 0,
	`sort_order` INTEGER DEFAULT 0,
	PRIMARY KEY(`id`)
);

CREATE INDEX `tracks_filename_index` ON `tracks` (
	`filename`
);

CREATE INDEX `tracks_external_id_index` ON `tracks` (
	`external_id`
);

CREATE INDEX `tracks_external_id_filetime_index` ON `tracks` (
	`external_id`,
	`filetime`
);

CREATE INDEX `tracks_dirty_index` ON `tracks` (
	`id`,
	`filename`,
	`filesize`,
	`filetime`
);

CREATE INDEX `tracks_by_source_index` ON `tracks` (
	`id`,
	`external_id`,
	`filename`,
	`source_id`
);

CREATE INDEX `trackmeta_index2` ON `track_meta` (
	`meta_value_id`,
	`track_id`
);

CREATE INDEX `trackmeta_index1` ON `track_meta` (
	`track_id`,
	`meta_value_id`
);

CREATE INDEX `trackgenre_index2` ON `track_genres` (
	`genre_id`,
	`track_id`
);

CREATE INDEX `trackgenre_index1` ON `track_genres` (
	`track_id`,
	`genre_id`
);

CREATE INDEX `trackartist_index2` ON `track_artists` (
	`artist_id`,
	`track_id`
);

CREATE INDEX `trackartist_index1` ON `track_artists` (
	`track_id`,
	`artist_id`
);

CREATE INDEX `thumbnail_index` ON `thumbnails` (
	`filesize`
);

CREATE INDEX `playlist_tracks_index_3` ON `playlist_tracks` (
	`track_external_id`
);

CREATE INDEX `playlist_tracks_index_2` ON `playlist_tracks` (
	`track_external_id`,
	`sort_order`
);

CREATE INDEX `playlist_tracks_index_1` ON `playlist_tracks` (
	`track_external_id`,
	`playlist_id`,
	`sort_order`
);

CREATE INDEX `paths_index` ON `paths` (
	`path`
);

CREATE INDEX `metavalues_index4` ON `meta_values` (
	`id`,
	`content`
);

CREATE INDEX `metavalues_index3` ON `meta_values` (
	`id`,
	`meta_key_id`,
	`content`
);

CREATE INDEX `metavalues_index2` ON `meta_values` (
	`content`
);

CREATE INDEX `metavalues_index1` ON `meta_values` (
	`meta_key_id`
);

CREATE INDEX `metakey_index2` ON `meta_keys` (
	`id`,
	`name`
);

CREATE INDEX `metakey_index1` ON `meta_keys` (
	`name`
);

CREATE INDEX `genre_index` ON `genres` (
	`sort_order`
);

CREATE INDEX `artist_index` ON `artists` (
	`sort_order`
);

CREATE INDEX `album_index` ON `albums` (
	`sort_order`
);

CREATE VIEW `tracks_view` AS
	SELECT DISTINCT
		`t`.`id`,
		`t`.`track`,
		`t`.`disc`,
		`t`.`bpm`,
		`t`.`duration`,
		`t`.`filesize`,
		`t`.`title`,
		`t`.`filename`,
		`t`.`thumbnail_id`,
		`t`.`external_id`,
		`t`.`rating`,
		`t`.`last_played`,
		`t`.`play_count`,
		`t`.`date_added`,
		`t`.`date_updated`,
		`al`.`name` AS `album`,
		`alar`.`name` AS `album_artist`,
		`gn`.`name` AS `genre`,
		`ar`.`name` AS `artist`,
		`t`.`filetime`,
		`t`.`visual_genre_id`,
		`t`.`visual_artist_id`,
		`t`.`album_artist_id`,
		`t`.`album_id`
	FROM
		`tracks` `t`,
		`albums` `al`,
		`artists` `alar`,
		`artists` `ar`,
		`genres` `gn`
	WHERE
		`t`.`album_id` = `al`.`id`
		AND `t`.`album_artist_id` = `alar`.`id`
		AND `t`.`visual_genre_id` = `gn`.`id`
		AND `t`.`visual_artist_id` = `ar`.`id`;

CREATE VIEW `extended_metadata` AS
	SELECT DISTINCT
		`tracks`.`id`,
		`tracks`.`external_id`,
		`tracks`.`source_id`,
		`meta_keys`.`id` AS `meta_key_id`,
		`track_meta`.`meta_value_id`,
		`meta_keys`.`name` AS `key`,
		`meta_values`.`content` AS `value`
	FROM
		`track_meta`,
		`meta_values`,
		`meta_keys`,
		`tracks`
	WHERE
		`tracks`.`id` = `track_meta`.`track_id`
		AND `meta_values`.`id` = `track_meta`.`meta_value_id`
		AND `meta_values`.`meta_key_id` = `meta_keys`.`id`;

COMMIT;
