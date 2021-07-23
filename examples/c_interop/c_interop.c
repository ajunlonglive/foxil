#include <stdio.h>

struct SimpleStruct {
    int age;
};

void SimpleStruct__show_name(struct SimpleStruct this) {
    printf("SimpleStruct.age: %d\n", this.age);
}
