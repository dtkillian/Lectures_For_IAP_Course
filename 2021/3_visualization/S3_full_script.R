#' ---------------------------------------------------------------------
#' *Visualization in R*
#' By Ted Papalexopoulos and Dan Killian 
#' 
#' Prior to running any code, you probably want to
#' Session > Set Working Directory > To Source File Location
#' ---------------------------------------------------------------------

#' ---------------------------------------------------------------------
#' Load the data
#' ---------------------------------------------------------------------
#' Let's load *tidyverse* package and AirBnB dataset, cleaning
#' the `price` column as last time.
library(tidyverse)

listings = read_csv('../data/listings.csv') %>% 
           mutate(price = parse_number(price),
                  rating = review_scores_rating, 
                  neighbourhood = neighbourhood_cleansed)

#' Instead of defining our own function `clean_price`, we use
#' the awesome `parse_number()` function to remove `$` and `,`.


#' ---------------------------------------------------------------------
#' Data-wrangling Recap
#' ---------------------------------------------------------------------
#' Let's recall the main verbs of dplyr:
#'   `select()`    to select columns by name.
#'   `filter()`    to select rows based on their values.
#'   `arrange()`   to reorder rows.
#'   `mutate()`    to add new columns.
#'   `summarise()` to aggregate.
#' And the all important `group_by()` function (more on that soon).


#' Use `filter()` to keep only listings that are "Downtown" AND 
#' rating is above 80.
listings %>% 
    filter(neighbourhood == "Downtown", 
           rating > 80) %>% 
    select(id, neighbourhood, rating) %>% 
    head


#' Use `arrange()` to sort by descending price
listings %>% 
    arrange(desc(price)) %>% 
    select(id, neighbourhood, price)


#' Use `mutate()` to create new columns (or overwrite existing 
#' ones). Here we clean the `review_score_rating`. 
listings %>%
    mutate(clean_rating = case_when(is.na(rating) ~ 0,
                                    rating > 100 ~ 100,
                                    TRUE ~ rating),
           pretty_price = paste("$", price, sep="")) %>%
    select(id, rating, clean_rating, pretty_price) %>% 
    head

#' Note the `case_when()` function for if/elseif/else logic.


#' Bonus verb: `count(...)` works like `table()` but in *long* format.
listings %>% count(room_type, bedrooms)

#' ---------------------------------------------------------------------
#' GROUP_BY
#' ---------------------------------------------------------------------
#' The `group_by(...)` verb creates groups of observations. 
#' By itself, it doesn't change the data frame at all. 
#' All it does is internally add a *meta-attribute* (namely 
#' what the groups of rows are), so that follow-up verbs
#' act on them individually.
#' 
#' We already saw how `group_by() %>% summarise()` aggregates:
listings %>% 
    group_by(neighbourhood) %>% 
    summarise(mean_rating = mean(rating, na.rm = T), 
              num_listings = n()) %>% 
    head


#' But it also changes how `mutate()` and `filter()` work!
#' The main difference is that anything they do, will be done 
#' *separately* for each group. 

#' Let's look at the `min_rank()` function. Try it on a vector:
min_rank(c(4, 15, 42, 16, 8, 23)) # Gives (1, 3, 6, 4, 2, 5)

#' So let's use `group_by() %>% mutate()` to add a column
#' for a listing's price rank *within its neighbourhood*:
listings %>%
    group_by(neighbourhood) %>%
    mutate(neighb_price_rank = min_rank(desc(price))) %>% 
    select(id, neighbourhood, price, neighb_price_rank) %>% 
    head

#' Because of `group_by()`, `min_rank()` acts on each 
#' neighbourhood's `price` column separately.


#' `filter()` also works within groups. Let's pick out the 
#' top 25% of listings in each neighbourhood by `rating`:
listings %>%
    group_by(neighbourhood) %>%
    filter(percent_rank(rating) >= 0.75) %>% 
    select(id, neighbourhood, rating)

#' Another use case: suppose we want the difference 
#' of price from the neighbourhood average:
listings %>% 
    group_by(neighbourhood) %>% 
    mutate(delta_price = price - mean(price)) %>% 
    select(id, neighbourhood, price, delta_price) %>% 
    tail

#' Side note: `group_by() %>% mutate()`, combined with the `lag()/lead()`
#' function are very useful when dealing with time series data; e.g.
#' calculating the difference of sales from one day to the next.

#' ---------------------------------------------------------------------
#' `dplyr` Concluding Remarks
#' ---------------------------------------------------------------------
#' We have by no means exhausted the capabilities of `dplyr`. Some
#' things we didn't cover:
#'   - Specifying variables by name patterns with selection helpers,
#'     `select(starts_with("Qtr"))`
#'   - Scoped verbs, for mutating/filtering/summarising multiple
#'     variables at the same time, e.g. `summarise_all(mean)` or
#'     `mutate_if(is.numeric, replace_na, 0)`.
#'   - Using the `!!sym(col_name)` to transform columns given as 
#'     strings (useful, for example, if the variable you want to
#'     summarise was passed as a string).

#' ---------------------------------------------------------------------
#' The Grammar of Graphics
#' ---------------------------------------------------------------------
#' Every ggplot should at the very least contain three elements: 
#'    *Data*: a dataframe
#'    *Aesthetics*: what we want to plot
#'    *Geometry*: how we want to plot it
#' ----------------------------------------------

#' Let's make a summary for nicer plots.
by_bedroom_rating = listings %>% 
    filter(!is.na(rating), 
           !is.na(bedrooms)) %>% 
    group_by(bedrooms, rating) %>% 
    summarise(med_price = median(price),
              num_listings = n())

by_bedroom_rating %>% head


#' We specify our *Data* (by_bedroom_rating),
#'                *Aesthetic mapping* (x and y) 
#'                *Geometry* (geom_point) 
#' and glue them together with `+`.
by_bedroom_rating %>% 
    ggplot(aes(x = rating, y = med_price)) + 
    geom_point()

#' Clean, intuitive and pretty. But most importantly, *extensible*. 

#' ---------------------------------------------------------------------
#'  Extensibility (a.k.a UNLIMITED POWERRRRRRR)
#' ---------------------------------------------------------------------
#' *Adding aesthetics*: Suppose we want to see the points 
#' broken out by the number of bedrooms. Let's add it as 
#' the `color` aesthetic:
by_bedroom_rating %>% 
    ggplot(aes(x = rating, 
               y = med_price, 
               color = factor(bedrooms))) + 
    geom_point()

#' `factor()` just tells R to treat something as categorical.


#' *Adding geoms*: We can also keep adding geoms to visualize the
#' same data in a different way. Here, we throw a linear best-fit
#' line for each bedroom class.
by_bedroom_rating %>% 
    ggplot(aes(x = rating, y = med_price, 
               color = factor(bedrooms))) + 
    geom_point() + 
    geom_smooth(method = lm)


#' Note that the aesthetics (x, y, color) propagate through 
#' both geoms (point and smooth). You can also provide 
#' geom-specific aesthetics: 
by_bedroom_rating %>% 
    ggplot(aes(x = rating, y = med_price)) + 
    geom_point(aes(color = factor(bedrooms))) + 
    geom_smooth(method = lm, color = "black")

#' Here we moved the `color` aesthetic to apply only to
#' `geom_point()`, and `geom_smooth()` will just add an
#' overall best-fit line.


#' ---------------------------------------------------------------------
#' More geometries and themes
#' ---------------------------------------------------------------------
#' Let's try to plot the median price by neighbourhood. Get the data...
by_neighbour = listings %>% 
    group_by(neighbourhood) %>% 
    summarise(med_price = median(price))


#' And make a bar plot with `geom_bar()`:
by_neighbour %>%
    ggplot(aes(x = neighbourhood, y = med_price)) +
    geom_bar(stat = 'identity')

#' We use `stat='identity'` to tell `geom_bar()` we want the height
#' of the bar to be the `y` value (*identity* as in "same as"). This
#' is fine because `by_neighbour` has one row per `neighbourhood`.
#' We'll see a different example of that in a bit.


#' For now, the x-axis looks horrible. Let's use `theme()` to 
#' change thematic (i.e. non-aesthetic) appearance stuff, e.g.
#' text rotation:
by_neighbour %>%
    ggplot(aes(x = neighbourhood, 
               y = med_price)) +
    geom_bar(stat = 'identity') +
    theme(axis.text.x = element_text(angle=60, hjust=1)) 


#' Following through on this idea, let's clean up a bit more: 
by_neighbour %>%
    ggplot(aes(x = reorder(neighbourhood, desc(med_price)), 
               y = med_price)) +
    geom_bar(stat = 'identity', fill = 'dark blue') +
    theme(axis.text.x = element_text(angle=60, hjust=1)) +
    labs(x='', y='Median price', title='Median daily price by neighborhood')

#' The only new tool here is `reorder()`, which simply reorders 
#' the first argument (`neighbourhood`) by the second (descending `price`).


#' And finally, let's look at an example `geom_bar()` using aggregation:
listings %>% 
    ggplot(aes(x = bedrooms, y = price)) + 
    geom_bar(stat = "summary", fun = median) + 
    labs(x = "# of Bedrooms", y = "Median Price ($)")

#' All we do is specify `stat='summary'`, and provide
#' the aggregation function as `fun=median`.

#' ---------------------------------------------------------------------
#' Facetting
#' ---------------------------------------------------------------------
#' Want a couple of extra dimensions in your plot? Try facetting, i.e.
#' breaking out your plot into subplots by some variable(s).

#' Using `facet_wrap()`, each value of `bedrooms` will get its 
#' own `geom_histogram()` of price:
listings %>%
    filter(!is.na(bedrooms)) %>% 
    ggplot(aes(x=price)) +
    geom_histogram(binwidth=50) +
    labs(x='Price', y='# of Listings') +
    xlim(0, 500) + 
    facet_wrap(~bedrooms, scales = "free_y") 

#' Note the `~` syntax (it defines a "formula").


#' Or use `facet_grid()` for facetting using two variables.
#' We ask for a grid of plots using a y ~ x formula:
listings %>%
    ggplot(aes(x=price, fill=room_type)) +
    geom_density(alpha=0.5) + 
    xlim(0, 500) + 
    labs(x='Price', y='Frac. of Listings', fill='Room type') +
    facet_grid(room_type~cancellation_policy) 


#' Side note: facetting is a case where having *long* data 
#' makes your life infinitely easier. Consider the company 
#' earnings example from last time, and think how you would
#' make histograms of earnings for each quarter separately:
#' with wide data it would be a manual ugly process, whereas
#' with long data a simple `+ facet_wrap(~Qtr)` works like 
#' a charm.


#' ---------------------------------------------------------------------
#' `ggplot` Concluding Remarks
#' ---------------------------------------------------------------------
#' Once again, we've only skimmed the surface of `ggplot`. As a 
#' general tip, the high-level process is:
#'    1) Decide what *geometry* is appropriate for your plot.
#'    2) Look at documentation to find what *aesthetics* it uses.
#'    3) Use `tidyverse` to wrangle your *data* so that columns 
#'       correspond to those aesthetics (e.g. convert long/wide).
#'    4) Fix it up with *theme* elements (labels, text).
#' 
#' Pointers to some things we didn't get to:
#'    - Compare distributions with `geom_boxplot()`, `geom_violin()`
#'    - Use `geom_text()` and the `label` to add floating text
#'    - Add error bars with `geom_errorbar()` and `geom_errorbarh()`
#'    - Overlay contour plots on `geom_point()` with `geom_density_2d()`
#'    - Plot cumulative distributions with `stat_ecdf()` 
#'    - 2d-histograms (a.k.a. color-maps) with `geom_tile()`
#'    - QQ-plots (for checking how normal something is) with `stat_qq()`
#'    - Change axis scales, e.g. to percentage or log with
#'      `+ scale_x_continuous(labels = scales::percent())`
#'    - Add `+ coord_flip()` to flip x and y variables (e.g. for
#'      horizontal bar charts).
#' 
#' And many many many more... A pretty extensive list can be found at:
#' http://www.sthda.com/english/wiki/be-awesome-in-ggplot2-a-practical-guide-to-be-highly-effective-r-software-and-data-visualization