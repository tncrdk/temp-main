// main_project/main.cpp
#include <iostream>
#include "lib_a.h"    // From lib_a project
#include "lib_a2.h"   // From lib_a project
#include "lib_b.h"    // From lib_b project
#include "lib_b2.h"   // From lib_b project

int main() {
    std::cout << "--- Main Application ---" << std::endl;

    // Use functions from lib_a
    std::cout << lib_a::get_message_a() << std::endl;
    int sum = lib_a::add_numbers(10, 5);
    std::cout << "Sum from lib_a: 10 + 5 = " << sum << std::endl;

    sum = lib_a::add_2(5);
    std::cout << "Sum_2 from lib_a: 2 + 5 = " << sum << std::endl;

    // Use functions from lib_b
    std::cout << lib_b::get_message_b() << std::endl;
    int product = lib_b::multiply_numbers(7, 3);
    std::cout << "Product from lib_b: 7 * 3 = " << product << std::endl;

    std::cout << "Application finished." << std::endl;
    return 0;
}
