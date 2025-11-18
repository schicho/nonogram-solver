#include "stacks.h"

#include <stdlib.h>

#define ARENA_IMPLEMENTATION
#include "arena.h"

struct _element {
    Item* item;
    struct _element* next;
};

struct _stack {
    Element* top;
    Arena* mem;
};

Stack* CreateStack() {
    Stack* stack = (Stack*)malloc(sizeof(Stack));
    stack->top = NULL;
    stack->mem = arena_create(1024 * 10000 * 8UL);
    return stack;
}

void Push(Stack* stack, Item* item) {
    if (stack == NULL) return;
    Element* element = (Element*)arena_alloc(stack->mem, sizeof(Element));
    Element* buffer = stack->top;
    stack->top = element;
    stack->top->next = buffer;
    stack->top->item = item;
}

Item* Pop(Stack* stack) {
    if (IsStackEmpty(stack)) return NULL;
    Element* top = stack->top;
    Item* item = top->item;
    stack->top = stack->top->next;
    // free(top);
    return item;
}

void ClearStack(Stack* stack) {
    // while (Pop(stack) != NULL);
    stack->top = NULL;
    arena_clear(stack->mem);
}

void DestroyStack(Stack* stack) {
    arena_destroy(stack->mem);
}

int IsStackEmpty(Stack* stack) {
    return (stack->top == NULL);
}

int IsInStack(Stack* stack, Item* item) {
    Element* e = stack->top;
    while (e != NULL) {
        if (item == e->item) return 1;
        e = e->next;
    }
    return 0;
}
