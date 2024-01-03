flowchart TD
    A[Start] --> B{Last tl?}
    B -->|Yes| C[Display tl]
    B -->|No| D{Tl col?}
    D -->|Yes| E[Display tl col]
    E -->|Select tl| C
    D -->|No| F[Create tl col]
    F --> E