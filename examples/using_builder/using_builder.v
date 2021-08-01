// Example showing how to use the `builder` module

module main

// We import the module (naturally it would be: `stunxfs.foxil.builder`)
import builder

fn main() {
	// We create a new `Builder` with the `new` function of the `builder` module
	mut b := builder.new()

	// We add an external function: `puts`
	b.new_extern_func('puts', [builder.str_type], false, builder.i32_type)

	// We create the main function
	mut main_fn := b.new_func('main', [], false, builder.i32_type)

	// We add a call to the `puts` function
	main_fn.call('puts', builder.i32_type, [
		// We pass it as an argument a string literal constant
		builder.Value(b.new_const('.str1', builder.SingleLiteral{'"Hello world!"', builder.str_type})),
	])

	// We add a return
	main_fn.instr('ret', [builder.Value(builder.SingleLiteral{'0', builder.i32_type})])

	// We add the `main` function to the builder
	b.add_func(mut main_fn)

	// We print the result
	println(b)
}
