<li class="row">
    <div class="col-sm-3 circular-image-container">
        <div class="circular-image">
            <img src="<?php block_field( 'image-url' ); ?>" alt="<?php block_field( 'image-alt' ); ?>">
        </div>
    </div>
    <div class="col-sm-9">
        <h3 class="normal-text"><?php block_field( 'title' ); ?></h3>
        <h4>
            <?php block_field( 'name' ); ?>
            <small><?php block_field( 'pronouns' ); ?></small>
        </h4>
        <div class="small">
            c/o <?php block_field( 'graduation-year' ); ?> | <?php block_field( 'team-postions' ); ?>  | <a href="<?php block_field( 'email' ); ?>">email</a>        
	</div>
        <br>
        <div><?php block_field( 'about' ); ?></div>
        <br>
        <div>
            <small>Currently working in</small><br>
            <?php block_field( 'professional-field' ); ?>
        </div>
        <div>
            <small><?php block_field( 'question-1' ); ?></small><br>
            <?php block_field( 'answer-1' ); ?>
        </div>
        <div>
            <small><?php block_field( 'question-2' ); ?></small><br>
            <?php block_field( 'answer-2' ); ?>
        </div>
    </div>
</li>

