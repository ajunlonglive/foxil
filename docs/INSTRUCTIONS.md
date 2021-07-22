# Foxil instructions list

## alloca
`alloca` stores a value on the stack and returns the address where that
value is stored.

### Syntax
```llvm
alloca T
alloca T, <Literal>
```

### Example
```llvm
%t  = alloca u32
%t2 = alloca u32, u32 4
```
