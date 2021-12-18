--drop database if exists covit;
--create database covit;
--use covit;



create table covit.country(
	id_country int primary key auto_increment not null,
    name varchar(100) not null unique
);


create table covit.province(
	id_province int not null primary key auto_increment,
    name varchar(100) not null,
    id_country_fk int not null,
    longitude double,
    latitude double,
    foreign key(id_country_fk) references country(id_country)
);

create table covit.positive_cases(
	id_case int not null primary key auto_increment,
	day int not null,
	month int not null,
	year int not null,
	full_date date not null,
	id_province_fk int not null,
	num_cases int not null,
	num_cases_acum int not null,
	foreign key (id_province_fk) references province(id_province)
);


create table covit.death_cases(
	id_case int not null primary key auto_increment,
	day int not null,
	month int not null,
	year int not null,
	full_date date not null,
	id_province_fk int not null,
	num_cases int not null,
	num_cases_acum int not null,
	foreign key (id_province_fk) references province(id_province)
);


create table covit.recovered_cases(
	id_case int not null primary key auto_increment,
	day int not null,
	month int not null,
	year int not null,
	full_date date not null,
	id_province_fk int not null,
	num_cases int not null,
	num_cases_acum int not null,
	foreign key (id_province_fk) references province(id_province)
);
