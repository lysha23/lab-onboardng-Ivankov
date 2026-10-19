def get_balance(user_id, db_connection):
    return db_connection[user_id]


def update_balance(user_id, new_balance, db_connection):
    db_connection[user_id] = new_balance


def process_transaction(user_id, amount, db_connection):
    status = "pending"
    if amount > 0:
        balance = get_balance(user_id, db_connection)
        new_balance = balance - amount
        update_balance(user_id, new_balance, db_connection)
        status = "approved"
    log_entry = "Transaction finished with status: " + status
    with open("audit_log.txt", "w", encoding="utf-8") as file:
        file.write(log_entry)
    return status


if __name__ == "__main__":
    database = {1: 1000}
    result = process_transaction(1, 250, database)
    print("Статус:", result)
    print("Баланс:", database[1])
