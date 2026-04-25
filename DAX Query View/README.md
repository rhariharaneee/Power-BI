# 📊 DAX Query View Scripts

A curated collection of DAX scripts for Power BI developers to inspect, audit, and understand their semantic models — directly inside **DAX Query View**, available in both **Power BI Desktop** and the **Power BI Service**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Power BI](https://img.shields.io/badge/Power%20BI-DAX%20Query%20View-F2C811?logo=powerbi&logoColor=black)](https://learn.microsoft.com/en-us/power-bi/transform-model/dax-query-view)

---

## 🧠 What is DAX Query View?

**DAX Query View** is a built-in query editor for writing and running DAX queries directly against a semantic model. It is available in:

- **Power BI Desktop** — via the left navigation panel
- **Power BI Service** — inside the semantic model editor (no Desktop required)

Queries use `EVALUATE` to return tabular results and can call powerful `INFO.*` metadata functions that expose the internals of your model — tables, measures, relationships, roles, dependencies, and more.

---

## 📁 Scripts

| File | Description |
|---|---|
| [`Model Summary.dax`](#model-summarydax) | High-level inventory of the model — table/column/measure counts, storage mode, version |
| [`Model Issues.dax`](#model-issuesdax) | Best practice health check with Pass/Fail results |
| [`Measure Dependency.dax`](#measure-dependencydax) | Full dependency map of every measure — what it references and what references it |
| [`PBI Roles.dax`](#pbi-rolesdax) | Lists all RLS roles and their DAX filter expressions per table |
| [`PBI Roles OLS.dax`](#pbi-roles-olsdax) | Breaks down Object-Level Security (OLS) permissions per role and column |
| [`PBI Role Members.dax`](#pbi-role-membersdax) | Shows users and AD groups assigned to each security role |
| [`RI.DAX`](#ridax) | Template for checking referential integrity violations in the model |

---

### `Model Summary.dax`

Provides a snapshot of the entire semantic model — table count, column count (split by calculated vs direct), measure count, relationships, storage mode, incremental refresh status, and the Power BI Desktop version used to build the model.

> Use this when onboarding onto an unfamiliar model or creating a model inventory.

---

### `Model Issues.dax`

Acts as a lightweight **Best Practice Analyzer**. Checks the model against common design standards and returns a **Pass/Fail** result for each rule, sorted with failures first.

Rules checked include: Auto date/time (local date tables), inactive relationships, bi-directional relationships, many-to-many relationships, missing dedicated date table, redundant columns, calculated columns, missing descriptions, and tables that may need partitioning.

> Use this before publishing a model to production or as part of a governance review.

---

### `Measure Dependency.dax`

Maps every measure's full dependency chain — showing which measures, columns, and tables it references, along with the source expressions. Useful for understanding layered measure logic.

> Use this when refactoring measures, renaming objects, or documenting the measure layer.

---

### `PBI Roles.dax`

Lists all **Row-Level Security (RLS)** roles defined in the model, with the DAX filter expression applied to each table per role, and the OLS permission type.

> Use this to audit RLS configuration or document security architecture.

---

### `PBI Roles OLS.dax`

Extends the roles view to include **Object-Level Security (OLS)** — showing which specific columns are restricted per role, and whether the permission is `Default`, `None` (hidden), or `Read`.

> Use this to verify column-level security is applied correctly.

---

### `PBI Role Members.dax`

Lists every user and AD group assigned to each security role in the model, including the identity provider and member type.

> Use this to audit who has access to which RLS role before or after deployment.

---

### `RI.DAX`

A template query that checks for **referential integrity violations** — rows in a table where a key value has no matching record in the related table. Adapt the table and column names to your own model.

> Use this as a starting point for data quality checks across any relationship.

---

## 🚀 How to Use

1. Open **Power BI Desktop** (or navigate to a semantic model in the **Power BI Service**)
2. Click the **DAX Query View** icon in the navigation panel
3. Open a new query tab
4. Copy and paste any `.dax` script from this repository into the editor
5. Press **Run** (`Shift + Enter`) to execute

> Queries saved in DAX Query View are stored inside the `.pbix` file and persist across sessions.

---

## 🔧 INFO Functions Used

These scripts rely on Power BI's `INFO.*` metadata functions — available exclusively in DAX Query View:

`INFO.TABLES()` · `INFO.COLUMNS()` · `INFO.MEASURES()` · `INFO.RELATIONSHIPS()` · `INFO.VIEW.TABLES()` · `INFO.VIEW.COLUMNS()` · `INFO.VIEW.RELATIONSHIPS()` · `INFO.ROLES()` · `INFO.ROLEMEMBERSHIPS()` · `INFO.TABLEPERMISSIONS()` · `INFO.COLUMNPERMISSIONS()` · `INFO.CALCDEPENDENCY()` · `INFO.PARTITIONS()` · `INFO.SEGMENTMAPSTORAGES()`

---

## 👤 Author

**Hariharan Rajendran**

- LinkedIn: [linkedin.com/in/imhariharanr](https://www.linkedin.com/in/imhariharanr/)
- GitHub: [github.com/rhariharaneee](https://github.com/rhariharaneee)

---

## 🤝 Contributing

Contributions are welcome! To add a script:

1. Fork the repository
2. Add your `.dax` file with a header comment (Author, Name, Version, Contact)
3. Open a Pull Request with a short description of what the script does

---

## 📄 License

```
MIT License

Copyright (c) 2024 Hariharan Rajendran

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
