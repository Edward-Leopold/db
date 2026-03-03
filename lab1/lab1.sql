
create table if not exists users (
    id SERIAL primary key,
    username VARCHAR(50) not null unique,
    email VARCHAR(100) not null unique
);

create table if not exists categories (
    id SERIAL primary key,
    user_id INTEGER not null,
    name VARCHAR(100) not null,
    type VARCHAR(10) not null check (type in ('income', 'expense')),
    foreign key (user_id) references users(id)
        on delete cascade
        on update cascade,
    constraint unique_user_category UNIQUE (user_id, name, type)
);

create table if not exists transactions (
    id SERIAL primary key,
    user_id INTEGER not null,
    category_id INTEGER not null,
    amount DECIMAL(10,2) not null check (amount > 0),
    date DATE not null,
    description TEXT,
    foreign key (user_id) references users(id)
        on delete cascade
        on update cascade,
    foreign key (category_id) references categories(id)
        on delete cascade
        on update cascade
);

create table if not exists goals (
    id SERIAL primary key,
    user_id INTEGER not null,
    name VARCHAR(100) not null,
    target_amount DECIMAL(10,2) not null check (target_amount > 0),
    current_amount DECIMAL(10,2) default 0 check (current_amount >= 0),
    deadline DATE,
    foreign key (user_id) references users(id)
        on delete cascade
        on update cascade,
    constraint unique_user_goal UNIQUE (user_id, name)
);

create table if not exists budgets (
    id SERIAL primary key,
    user_id INTEGER not null,
    category_id INTEGER not null,
    month VARCHAR(10) not null, 
    amount_limit DECIMAL(10,2) not null check (amount_limit > 0),
    foreign key (user_id) references users(id)
        on delete cascade
        on update cascade,
    foreign key (category_id) references categories(id)
        on delete cascade
        on update cascade,
    constraint unique_budget UNIQUE (user_id, category_id, month)
);