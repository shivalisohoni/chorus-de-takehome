# Task Tracking Data Model

## Overview
This model enables tracking of **recurring tasks** and their **individual occurrences** over time.

People can be assigned to tasks, and each occurrence of a recurring task can have its own **status** — 
for example, *Not Started*, *In Progress*, or *Completed*.

---

## 🎯 Key Entities

| Table | Purpose |
|--------|----------|
| **Person** | Stores information about people who can be assigned to tasks. |
| **Task** | Represents a base task (e.g., “Clean lab”), including cadence and start/end. |
| **TaskOccurrence** | Represents each recurrence (e.g., “Clean lab on Nov 10”). |
| **TaskAssignment** | Maps people to specific tasks or occurrences. |

---

## Schema Overview

The full DDL is in [`sql/task_data_model.sql`](task_data_model.sql).

```mermaid
erDiagram
    Person {
        UUID id PK "Primary key"
        VARCHAR name "Person full name"
        VARCHAR email "Contact email"
        TIMESTAMP created_at "Record creation timestamp"
    }

    Task {
        UUID id PK "Primary key"
        VARCHAR name "Task title"
        TEXT description "Task details or notes"
        VARCHAR cadence "daily | weekly | monthly | once"
        INT total_occurrences "How many times the task should repeat"
        DATE start_date "Task start date"
        DATE end_date "Optional task end date"
        TIMESTAMP created_at "Record creation timestamp"
    }

    TaskOccurrence {
        UUID id PK "Primary key"
        UUID task_id FK "References Task(id)"
        DATE occurrence_date "Date of the specific occurrence"
        VARCHAR status "Not Started | In Progress | Completed"
        TIMESTAMP created_at "Record creation timestamp"
    }

    TaskAssignment {
        UUID id PK "Primary key"
        UUID task_id FK "References Task(id)"
        UUID person_id FK "References Person(id)"
        UUID occurrence_id FK "References TaskOccurrence(id)"
        TIMESTAMP assigned_at "When the person was assigned"
    }

    %% Relationships
    Person ||--o{ TaskAssignment : "assigned to"
    Task ||--o{ TaskOccurrence : "has"
    Task ||--o{ TaskAssignment : "includes"
    TaskOccurrence ||--o{ TaskAssignment : "assigned via occurrence"
