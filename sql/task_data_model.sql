/********************************************************************
 Data Model: Task Tracking System
 ********************************************************************/

-- People who can be assigned to tasks
CREATE TABLE Person (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tasks define what needs to be done and how often
CREATE TABLE Task (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cadence VARCHAR(20),            -- daily, weekly, monthly, once
    total_occurrences INT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Each instance of a recurring task
CREATE TABLE TaskOccurrence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES Task(id),
    occurrence_date DATE,
    status VARCHAR(20),             -- Not Started, In Progress, Completed
    created_at TIMESTAMP DEFAULT NOW()
);

-- Assign people to tasks or specific occurrences
CREATE TABLE TaskAssignment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES Task(id),
    person_id UUID REFERENCES Person(id),
    occurrence_id UUID REFERENCES TaskOccurrence(id),
    assigned_at TIMESTAMP DEFAULT NOW()
);
