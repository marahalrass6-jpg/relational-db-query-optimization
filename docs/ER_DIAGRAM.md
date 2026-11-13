# Entity Relationship Diagram

```mermaid
erDiagram
  DEPARTMENTS ||--o{ EMPLOYEES : contains
  EMPLOYEES ||--o{ EMPLOYEES : manages
  CUSTOMERS ||--o{ ORDERS : places
  EMPLOYEES ||--o{ ORDERS : manages
  LOCATIONS ||--o{ ORDERS : fulfills
  CATEGORIES ||--o{ PRODUCTS : classifies
  LOCATIONS ||--o{ INVENTORY : stores
  PRODUCTS ||--o{ INVENTORY : stocked
  ORDERS ||--|{ ORDER_ITEMS : contains
  PRODUCTS ||--o{ ORDER_ITEMS : sold_as
  ORDERS ||--o{ PAYMENTS : receives
  ORDERS ||--o| SHIPMENTS : has
  ORDERS ||--o{ ORDER_STATUS_HISTORY : records
  EMPLOYEES ||--o{ ORDER_STATUS_HISTORY : changes
```

The schema uses `order_items` as the associative/detail relation between orders and products, while `inventory` resolves the many-to-many relationship between locations and products.
