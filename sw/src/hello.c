// We are not using the standard library, so we don't include stdio.h
// Instead, we provide a forward declaration of our own puts function.
int puts(const char *s);

int main() {
    puts("Hello, RISC-V!");
    return 0;
} 