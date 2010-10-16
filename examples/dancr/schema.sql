create table if not exists entries (
  id integer primary key autoincrement,
  title string not null,
  text string not null
);
