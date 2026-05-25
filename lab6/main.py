from fastapi import FastAPI, Depends, HTTPException, Query
from sqlalchemy import create_engine, Column, Integer, String, Numeric, Date, ForeignKey, text, desc, asc
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import date as date_type

DATABASE_URL = "postgresql://postgres:arc1vevod@localhost:5432/finance_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- ORM ---
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True)
    email = Column(String, unique=True)
    budget = Column(Numeric)

class Category(Base):
    __tablename__ = "categories"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String)
    type = Column(String)

class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    category_id = Column(Integer, ForeignKey("categories.id"))
    amount = Column(Numeric)
    date = Column(Date)
    description = Column(String)

class Goal(Base):
    __tablename__ = "goals"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String)
    target_amount = Column(Numeric)
    current_amount = Column(Numeric)
    deadline = Column(Date)

# --- Validation Schemas Pydantic ---

class UserBase(BaseModel):
    username: str
    email: str
    budget: float

class UserSchema(UserBase):
    id: int
    class Config: from_attributes = True

class CategoryBase(BaseModel):
    user_id: int
    name: str
    type: str

class CategorySchema(CategoryBase):
    id: int
    class Config: from_attributes = True

class TransactionBase(BaseModel):
    user_id: int
    category_id: int
    amount: float
    date: date_type
    description: Optional[str]

class TransactionSchema(TransactionBase):
    id: int
    class Config: from_attributes = True

class GoalBase(BaseModel):
    user_id: int
    name: str
    target_amount: float
    current_amount: float
    deadline: Optional[date_type]

class GoalSchema(GoalBase):
    id: int
    class Config: from_attributes = True

# --- Initialization ---
app = FastAPI(title="Finance Full REST API")

def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()

# --- Endpoints ---
# --- USERS CRUD ---
@app.get("/users", response_model=List[UserSchema], tags=["Users"])
def get_users(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1, description="Номер страницы (начиная с 1)"),
    limit: int = Query(10, ge=1, le=100, description="Количество записей на страницу (макс. 100)"),
    sort_by: str = Query("username", description="Поле для сортировки (например, username или budget)"),
    order: str = Query("asc", description="Направление сортировки: 'asc' (от А до Я) или 'desc' (от Я до А)")
):
    query = db.query(User)
    column = getattr(User, sort_by)
    query = query.order_by(asc(column) if order == "asc" else desc(column))
    
    return query.offset((page-1)*limit).limit(limit).all()

@app.get("/users/{id}", response_model=UserSchema, tags=["Users"])
def get_user(id: int, db: Session = Depends(get_db)):
    item = db.query(User).get(id)
    if not item: raise HTTPException(404, "User not found")
    return item

@app.post("/users", response_model=UserSchema, tags=["Users"])
def create_user(data: UserBase, db: Session = Depends(get_db)):
    obj = User(**data.dict())
    db.add(obj); db.commit(); db.refresh(obj)
    return obj

@app.put("/users/{id}", response_model=UserSchema, tags=["Users"])
def update_user(id: int, data: UserBase, db: Session = Depends(get_db)):
    obj = db.query(User).get(id)
    if not obj: raise HTTPException(404, "Not found")
    for k, v in data.dict().items(): setattr(obj, k, v)
    db.commit(); return obj

@app.delete("/users/{id}", tags=["Users"])
def delete_user(id: int, db: Session = Depends(get_db)):
    obj = db.query(User).get(id)
    if not obj: raise HTTPException(404, "Not found")
    db.delete(obj); db.commit(); return {"done": True}

# --- CATEGORIES CRUD ---
@app.get("/categories", response_model=List[CategorySchema], tags=["Categories"])
def get_categories(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1, description="Номер страницы"),
    limit: int = Query(10, ge=1, le=100, description="Записей на страницу"),
    type_filter: Optional[str] = Query(None, description="Фильтр по типу: 'income' (доходы) или 'expense' (расходы)")
):
    query = db.query(Category)
    if type_filter:
        query = query.filter(Category.type == type_filter)
    
    return query.offset((page-1)*limit).limit(limit).all()

@app.get("/categories/{id}", response_model=CategorySchema, tags=["Categories"])
def get_category(id: int, db: Session = Depends(get_db)):
    item = db.query(Category).get(id)
    if not item: raise HTTPException(404, "Category not found")
    return item

@app.post("/categories", response_model=CategorySchema, tags=["Categories"])
def create_category(data: CategoryBase, db: Session = Depends(get_db)):
    obj = Category(**data.dict())
    db.add(obj); db.commit(); db.refresh(obj)
    return obj

@app.put("/categories/{id}", response_model=CategorySchema, tags=["Categories"])
def update_category(id: int, data: CategoryBase, db: Session = Depends(get_db)):
    obj = db.query(Category).get(id)
    if not obj: raise HTTPException(404, "Not found")
    for k, v in data.dict().items(): setattr(obj, k, v)
    db.commit(); return obj

@app.delete("/categories/{id}", tags=["Categories"])
def delete_category(id: int, db: Session = Depends(get_db)):
    obj = db.query(Category).get(id)
    if not obj: raise HTTPException(404, "Not found")
    db.delete(obj); db.commit(); return {"done": True}

# --- TRANSACTIONS CRUD  ---
@app.get("/transactions", response_model=List[TransactionSchema], tags=["Transactions"])
def get_transactions(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1, description="Номер страницы"),
    limit: int = Query(10, ge=1, le=100, description="Записей на страницу"),
    min_amount: Optional[float] = Query(None, description="Показать транзакции дороже этой суммы"),
    sort_by: str = Query("date", description="Сортировать по: date, amount"),
    order: str = Query("desc", description="Направление: asc (старые в начале) или desc (новые в начале)")
):
    query = db.query(Transaction)
    if min_amount:
        query = query.filter(Transaction.amount >= min_amount)
    
    column = getattr(Transaction, sort_by)
    query = query.order_by(asc(column) if order == "asc" else desc(column))
    
    return query.offset((page-1)*limit).limit(limit).all()

@app.get("/transactions/{id}", response_model=TransactionSchema, tags=["Transactions"])
def get_transaction(id: int, db: Session = Depends(get_db)):
    item = db.query(Transaction).get(id)
    if not item: raise HTTPException(404, "Not found")
    return item

@app.post("/transactions", response_model=TransactionSchema, tags=["Transactions"])
def create_transaction(data: TransactionBase, db: Session = Depends(get_db)):
    obj = Transaction(**data.dict())
    db.add(obj); db.commit(); db.refresh(obj)
    return obj

@app.put("/transactions/{id}", response_model=TransactionSchema, tags=["Transactions"])
def update_transaction(id: int, data: TransactionBase, db: Session = Depends(get_db)):
    obj = db.query(Transaction).get(id)
    if not obj: raise HTTPException(404, "Not found")
    for k, v in data.dict().items(): setattr(obj, k, v)
    db.commit(); return obj

@app.delete("/transactions/{id}", tags=["Transactions"])
def delete_transaction(id: int, db: Session = Depends(get_db)):
    obj = db.query(Transaction).get(id)
    if not obj: raise HTTPException(404, "Not found")
    db.delete(obj); db.commit(); return {"done": True}

# --- GOALS CRUD ---
@app.get("/goals", response_model=List[GoalSchema], tags=["Goals"])
def get_goals(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1, description="Номер страницы"),
    limit: int = Query(10, ge=1, le=100, description="Записей на страницу"),
    sort_by: str = Query("target_amount", description="Сортировать по: target_amount или current_amount"),
    order: str = Query("desc", description="Направление: asc (по возрастанию) или desc (по убыванию)")
):
    query = db.query(Goal)
    column = getattr(Goal, sort_by)
    query = query.order_by(asc(column) if order == "asc" else desc(column))
    
    return query.offset((page-1)*limit).limit(limit).all()

@app.get("/goals/{id}", response_model=GoalSchema, tags=["Goals"])
def get_goal(id: int, db: Session = Depends(get_db)):
    item = db.query(Goal).get(id)
    if not item: raise HTTPException(404, "Goal not found")
    return item

@app.post("/goals", response_model=GoalSchema, tags=["Goals"])
def create_goal(data: GoalBase, db: Session = Depends(get_db)):
    obj = Goal(**data.dict())
    db.add(obj); db.commit(); db.refresh(obj)
    return obj

@app.put("/goals/{id}", response_model=GoalSchema, tags=["Goals"])
def update_goal(id: int, data: GoalBase, db: Session = Depends(get_db)):
    obj = db.query(Goal).get(id)
    if not obj: raise HTTPException(404, "Not found")
    for k, v in data.dict().items(): setattr(obj, k, v)
    db.commit(); return obj

@app.delete("/goals/{id}", tags=["Goals"])
def delete_goal(id: int, db: Session = Depends(get_db)):
    obj = db.query(Goal).get(id)
    if not obj: raise HTTPException(404, "Not found")
    db.delete(obj); db.commit(); return {"done": True}

# --- Views ---
@app.get("/reports/all-transactions-view", tags=["Reports"])
def view_all_tx(db: Session = Depends(get_db)):
    return db.execute(text("SELECT * FROM all_transactions")).mappings().all()

# --- Procedures and Functions ---
@app.post("/actions/call-add-transaction-proc", tags=["Logic"])
def call_proc(u_id: int, c_id: int, amt: float, desc: str, db: Session = Depends(get_db)):
    db.execute(text("CALL sp_add_transaction(:u, :c, :a, :d)"), {"u":u_id, "c":c_id, "a":amt, "d":desc})
    db.commit()
    return {"status": "Success"}

@app.get("/actions/get-goal-progress-func/{id}", tags=["Logic"])
def call_func(id: int, db: Session = Depends(get_db)):
    val = db.execute(text("SELECT fn_get_goal_progress(:id)"), {"id": id}).scalar()
    return {"progress": val}

# --- Agregations ---
@app.get("/reports/user-totals", tags=["Reports"])
def report_totals(db: Session = Depends(get_db)):
    return db.execute(text("SELECT * FROM user_totals")).mappings().all()