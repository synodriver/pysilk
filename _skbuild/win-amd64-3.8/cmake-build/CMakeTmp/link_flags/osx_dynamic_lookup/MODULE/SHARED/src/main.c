
      #include <stdlib.h>
      #include <stdio.h>
      #include <number.h>
    
        #include <dlfcn.h>
      
      int my_count() {
        int result = get_number();
        set_number(result + 1);
        return result;
      }

      int main(int argc, char **argv) {
        int result;
    
        void *counter_module;
        int (*count)(void);

        counter_module = dlopen("./counter.so", RTLD_LAZY | RTLD_GLOBAL);
        if(!counter_module) goto error;

        count = dlsym(counter_module, "count");
        if(!count) goto error;
      
        result = count()    != 0 ? EXIT_FAILURE :
                 my_count() != 1 ? EXIT_FAILURE :
                 my_count() != 2 ? EXIT_FAILURE :
                 count()    != 3 ? EXIT_FAILURE :
                 count()    != 4 ? EXIT_FAILURE :
                 count()    != 5 ? EXIT_FAILURE :
                 my_count() != 6 ? EXIT_FAILURE : EXIT_SUCCESS;
    
        goto done;
        error:
          fprintf(stderr, "Error occured:\n    %s\n", dlerror());
          result = 1;

        done:
          if(counter_module) dlclose(counter_module);
      
          return result;
      }
    