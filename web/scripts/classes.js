class Account {
  constructor(id, name, balance, transactions) {
    this.id = id;
    this.name = name;
    this.balance = balance;
    this.transactions = transactions;
  }

  PrettyPrintBalance() {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "usd",
    })
      .format(this.balance)
      .toString();
  }
}

class Transaction {
  constructor(type, amount, description, targetId) {
    this.type = type;
    this.amount = amount;
    this.description = description;

    if (targetId) this.targetId = targetId;
  }

  PrettyPrintAmount() {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "usd",
    })
      .format(this.amount)
      .toString();
  }

  GetDescription() {
    if (this.description?.trim()) {
      return (
        this.description +
        `${(() => {
          if (this.type == "transfer_sent")
            return `&nbsp;(You → ${this.targetId})`;
          else if (this.type == "transfer_recieved")
            return `&nbsp;(${this.targetId} → You)`;
          else if (this.type == "deposit")
            return `&nbsp;(<span style="color: #73f5e4">+${this.PrettyPrintAmount()}</span>)`;
          else if (this.type == "withdraw")
            return `&nbsp;(<span style="color: #ed5365">-${this.PrettyPrintAmount()}</span>)`;
          else return ``;
        })()}`
      );
    }

    switch (this.type) {
      case "deposit":
        this.description = `You have deposited ${this.PrettyPrintAmount()}`;
        break;

      case "transfer_sent":
        this.description = `You have sent ${this.PrettyPrintAmount()} to ${
          this.targetId
        }`;
        break;

      case "transfer_recieved":
        this.description = `You have recieved ${this.PrettyPrintAmount()} from ${
          this.targetId
        }`;
        break;

      case "withdraw":
        this.description = `You have withdrawed ${this.PrettyPrintAmount()}`;
        break;
    }

    return this.description;
  }
}
