# Cortex Analyst Natural Language Queries for RDF Semantic Views

This document provides example natural language queries that can be used with Snowflake's Cortex Analyst to query the RDF semantic views created in this demo.

## Overview

The semantic views created in this demo are optimized for natural language querying through Cortex Analyst. The semantic layer includes:

- **Rich synonyms** for better language understanding
- **Comprehensive metrics** for business analysis
- **Intuitive dimensions** for filtering and grouping
- **Clear relationships** between entities
- **Business-friendly comments** for context

## Example Natural Language Queries

### Revenue and Sales Analysis

```
"What was our total revenue last year?"
"Show me monthly sales trends"
"What's the average order value?"
"Which month had the highest revenue?"
"Compare revenue by quarter"
"What's our total sales this year versus last year?"
```

### Customer Analysis

```
"Who are our top customers by revenue?"
"Show me customers who placed the most orders"
"What's the average number of orders per customer?"
"Which customers have the highest lifetime value?"
"Show me repeat customers"
"What's our customer retention rate?"
```

### Product and Inventory Analysis

```
"Which products are out of stock?"
"Show me products with low inventory"
"What's our total inventory value?"
"Which products have the highest prices?"
"Show me products by category"
"What's the average product price?"
```

### Category Performance

```
"Which product categories generate the most revenue?"
"Show me sales by category"
"Which category has the most products?"
"Compare category performance"
"What's the average price by category?"
```

### Supplier Analysis

```
"Which suppliers provide the most products?"
"Show me supplier performance"
"Which vendors have the highest value products?"
"List all suppliers and their product counts"
```

### Time-based Analysis

```
"Show me daily order trends"
"What are our peak sales days?"
"Compare this month to last month"
"Show me year-over-year growth"
"What day of the week do we get the most orders?"
```

### Inventory Management

```
"Show me stock levels by product"
"Which products need restocking?"
"What's our inventory turnover?"
"Show me high-value inventory items"
"Which categories are running low on stock?"
```

### Combined Analysis

```
"Show me revenue trends by customer segment"
"Which categories have the best performing customers?"
"Compare product performance across different time periods"
"Show me inventory value by supplier"
"What's the relationship between price and sales volume?"
```

## Query Structure for Cortex Analyst

When using Cortex Analyst with these semantic views, you can ask questions in natural language that reference:

### Entities (with synonyms)
- Products (items, merchandise, goods, catalog items)
- Customers (clients, buyers, users, shoppers)
- Orders (purchases, transactions, sales, checkouts)
- Categories (product types, classifications, groups)
- Suppliers (vendors, manufacturers, distributors)

### Metrics (with synonyms)
- Total revenue (total sales, revenue, gross sales)
- Average order value (AOV, mean order value)
- Customer lifetime value (CLV, revenue per customer)
- Inventory value (stock value, inventory worth)
- Order count (number of orders, transaction count)

### Dimensions (with synonyms)
- Product name (item name, product title)
- Customer name (client name, buyer name)
- Category name (product category, type, classification)
- Order date (purchase date, transaction date)
- Price tier (price range, price category)
- Stock status (availability, inventory status)

## Advanced Query Examples

### Business Intelligence Queries

```
"Show me our top 10 customers by revenue and their order frequency"
"Which product categories are most profitable?"
"What's our month-over-month growth rate?"
"Show me customer acquisition trends"
"Which suppliers deliver the highest margin products?"
```

### Operational Queries

```
"Alert me to products with less than 10 units in stock"
"Show me orders that exceed $1000 in value"
"Which customers haven't ordered in the last 3 months?"
"What's our average fulfillment time by supplier?"
```

### Strategic Analysis Queries

```
"What's the correlation between product price and sales volume?"
"Show me market share by category"
"Which customer segments are growing fastest?"
"What's our customer churn rate?"
"How does seasonality affect our sales?"
```

## Integration with Cortex Analyst REST API

To use these semantic views with the Cortex Analyst REST API, reference the semantic view in your API calls:

```json
{
  "messages": [
    {
      "role": "user",
      "content": "What was our total revenue last month?"
    }
  ],
  "semantic_model": {
    "database": "RDF_SEMANTIC_DB",
    "schema": "SEMANTIC_VIEWS", 
    "semantic_view": "ECOMMERCE_SEMANTIC_MODEL"
  }
}
```

## Benefits of Semantic Views for Natural Language Queries

1. **Intuitive Language**: Users can ask questions in natural business language
2. **Rich Synonyms**: Multiple ways to refer to the same concepts
3. **Business Context**: Comments provide context for better understanding
4. **Comprehensive Metrics**: Pre-calculated business measures
5. **Flexible Dimensions**: Multiple ways to slice and dice data
6. **Relationship Awareness**: Understanding of how entities connect

## Tips for Effective Queries

1. **Use business terminology** rather than technical database terms
2. **Be specific about time periods** when asking about trends
3. **Combine metrics with dimensions** for richer analysis
4. **Use synonyms** if the initial query doesn't work as expected
5. **Ask follow-up questions** to drill down into interesting findings

The semantic views in this demo provide a rich foundation for natural language business intelligence through Cortex Analyst, enabling users to get insights without writing SQL.