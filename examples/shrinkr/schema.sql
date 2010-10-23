create table if not exists link (
  id integer primary key,
  code string not null,
  url string not null,
  count integer not null
);
