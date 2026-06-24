# Group Kind Note

OMONI now persists an optional `groupKind` field on `SDGroup`.

Current intended values:

- `expense`
- `income`

Product intent:

- A group should represent one financial lane, not a mix of expense and income records.
- Expense groups keep the current category meaning, such as `Hogar` or `Ocio`.
- Income groups will reuse categories as income-source labels, such as `Pulseras` or `Salario`.
- While the MVP UI does not expose this field yet, the database is ready so future hero copy can resolve labels like `Gasto de Hogar` or `Ingresos Pulseras`.

Implementation note:

- The field is optional in this rollout so older backup payloads and pre-UI records remain compatible.
- When the value is missing or invalid, the app resolves it as `expense`.
