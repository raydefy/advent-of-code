# require './src/2019-05.rb'
require 'test/unit'
require 'byebug'

class Instruction
	attr_reader :opcode, :p1, :p2, :p3, :ptr

	def initialize(int, ptr=0)
		str = int.to_s
		@code = str
		o1, o2, p1, p2, p3, p4 = str.reverse.chars.map{|e| e.to_i}
		if str.size < 2
			o2 = p1 = p2 = p3 = 0
		end
		@opcode = o1 + (10 * o2) # str[-2,2].to_i
		@p1 = p1 || 0
		@p2 = p2 || 0
		@p3 = p3 || 0
		@ptr = ptr
		# puts "%p" % self
	end
end

class IntComputer
	attr_reader :ram, :input, :output_result
	attr_accessor :input
	OP_ADD = 1
	OP_MULT = 2
	OP_INPUT = 3
	OP_OUTPUT = 4
	OP_JUMP_T = 5
	OP_JUMP_F = 6
	OP_LESS_T = 7
	OP_EQUALS = 8
	OP_HALT = 99

	def ram=(program)
		if program.is_a?(String)
			@ram = program.split(',').map{|e| e.to_i}
		else
			@ram = program
		end
	end

	def initialize(program=nil)
		ram = program
	end

	def op_add(instruction)
		ptr = instruction.ptr
		pos_v3 = ram[ptr + 3]
		ram[pos_v3] = @v1 + @v2
	end

	def op_mult(instruction)
		ptr = instruction.ptr
		pos_v3 = ram[ptr + 3]
		ram[pos_v3] = @v1 * @v2
	end

	# Opcode 3 takes a single integer as input
	# and saves it to the position given by its only parameter.
	def op_input(instruction)
		value = @input.shift or raise 'No more input'
		value = value.to_i
		#puts "Inputing value #{value}"
		ptr = instruction.ptr
		pos_v1 = ram[ptr + 1]
		ram[pos_v1] = value
	end

	def op_output(instruction)
		ptr = instruction.ptr
		pos_v1 = ram[ptr + 1]
		value = instruction.p1 == 0 ? ram[pos_v1] : pos_v1
		#puts "output @#{ptr + 1} #{value}"
		@output_result = value
	end

	def get_ram(ptr, mode, param_id)
		if value = ram[ptr + param_id]
		mode == 0 ? ram[value] : value
		end
	end

	def op_jump(instruction,mode=true)
		ptr = instruction.ptr
		return @v2 if mode == true and @v1 != 0
		return @v2 if mode == false and @v1 == 0
		nil
	end

	def op_less_than(instruction)
		ptr = instruction.ptr
		v1 = get_ram(ptr, instruction.p1, 1)
		v2 = get_ram(ptr, instruction.p2, 2)
		v3 = get_ram(ptr, 1, 3)
		value = v1 < v2 ? 1 : 0
		ram[v3] = value
	end

	# Opcode 8 is equals: if the first parameter is equal to the
	# second parameter, it stores 1 in the position given by the
	# third parameter. Otherwise, it stores 0.
	def op_equals(instruction)
		ptr = instruction.ptr
		pos_v1, pos_v2, pos_v3 = ram[ptr + 1, 3]
		v1 = instruction.p1 == 0 ? ram[pos_v1] : pos_v1
		v2 = instruction.p2 == 0 ? ram[pos_v2] : pos_v2
		value = v1 == v2 ? 1 : 0
		ram[pos_v3] = value
	end

	def execute(program=nil)
		if program
			self.ram= program
		end
		#@input << 1 if @input.size == 0
		result = nil
		op_ptr = 0
		loop do
			next_op_ptr = 4
			opcode = ram[op_ptr]
			instruction = Instruction.new(opcode, op_ptr)
			@v1 = get_ram(instruction.ptr, instruction.p1, 1)
			@v2 = get_ram(instruction.ptr, instruction.p2, 2)

			if instruction.opcode == OP_ADD
				op_add(instruction)
			elsif instruction.opcode == OP_MULT
				op_mult(instruction)
			elsif instruction.opcode == OP_INPUT
				next_op_ptr = 2
				op_input(instruction)
			elsif instruction.opcode == OP_OUTPUT
				next_op_ptr = 2
				op_output(instruction)
			elsif instruction.opcode == OP_JUMP_T or
			      instruction.opcode == OP_JUMP_F
				next_op_ptr = 3
				if jump = op_jump(instruction,instruction.opcode == OP_JUMP_T)
					op_ptr = jump
					next_op_ptr = 0
				end
			elsif instruction.opcode == OP_LESS_T
				op_less_than(instruction)
			elsif instruction.opcode == OP_EQUALS
				op_equals(instruction)
			elsif instruction.opcode == OP_HALT
				result = ram[0]
				break
			else
				raise "Bad opcode #{opcode}"
			end
			op_ptr += next_op_ptr
		end
		result
		@output_result.to_i
	end
end

def maxamp(program, data)
	ic = IntComputer.new
	result = 0
	data.each do |amp|
		ic.input = [amp, result]
		result = ic.execute(program)
	end
	puts "output: %s" % result
	result
end

if __FILE__ == $0
	extend Test::Unit::Assertions

	filename = ARGV[0] || 'data/2019-05.input.txt'
	program = File.read(filename).chomp

	program = '3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0'
	data = [4,3,2,1,0]
	assert_equal 43210, maxamp(program, data)

	data = [0, 1, 2, 3, 4]
	assert_equal 54321, maxamp('3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0', data)

	data = [1,0,4,3,2]
	assert_equal 65210, maxamp('3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0', data)
end